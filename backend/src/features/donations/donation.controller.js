import { prisma } from '../../config/prisma.js';

const normalizeAmount = (value) => {
  const amount = parseFloat(value);
  return Number.isFinite(amount) ? amount : null;
};

const buildEsewaTransactionId = () => `ESWA-${Date.now()}-${Math.floor(Math.random() * 100000)}`;

const normalizeStatus = (status) => {
  const normalized = String(status || '').toLowerCase();
  if (['complete', 'completed'].includes(normalized)) return 'completed';
  if (['failed', 'failure'].includes(normalized)) return 'failed';
  if (['refunded'].includes(normalized)) return 'refunded';
  return 'pending';
};

const isEsewaPaymentMethod = (pm) =>
  ['esewa_wallet', 'esewa', 'card'].includes(String(pm || '').toLowerCase());

const donationUserData = (req) => {
  const userId = req.user?.userId;
  return userId ? { userId } : {};
};

export const getBankInfo = async (req, res) => {
  try {
    res.json({
      bankName: process.env.BANK_NAME || '',
      accountName: process.env.BANK_ACCOUNT_NAME || '',
      accountNumber: process.env.BANK_ACCOUNT_NUMBER || '',
      branch: process.env.BANK_BRANCH || '',
      swift: process.env.BANK_SWIFT || ''
    });
  } catch (error) {
    console.error('Get bank info error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const createDonation = async (req, res) => {
  try {
    const {
      donorName,
      donorEmail,
      amount,
      paymentMethod,
      transactionId,
      bankReference,
      receiptUrl
    } = req.body;
    const amountValue = normalizeAmount(amount);

    if (!amountValue || amountValue <= 0) {
      return res.status(400).json({ message: 'Amount must be a positive number' });
    }

    const pm = String(paymentMethod || '').toLowerCase();

    if (pm === 'card' || pm === 'esewa_wallet' || pm === 'esewa') {
      return res.status(400).json({
        message: 'Use the in-app payment flow for card and eSewa (initiate payment from the Donate screen).'
      });
    }

    if (pm === 'bank_transfer') {
      if (!bankReference || String(bankReference).trim() === '') {
        return res.status(400).json({
          message: 'Bank reference or transfer ID is required for bank transfers'
        });
      }
      const donation = await prisma.donation.create({
        data: {
          ...donationUserData(req),
          donorName: donorName?.trim() || null,
          donorEmail: donorEmail?.trim() || null,
          amount: amountValue,
          paymentMethod: 'bank_transfer',
          bankReference: String(bankReference).trim(),
          receiptUrl: receiptUrl?.trim() || null,
          transactionId: null,
          status: 'pending',
          campaignId: req.body.campaignId ? parseInt(req.body.campaignId) : null
        }
      });

      return res.status(201).json({
        message: 'Bank transfer recorded. It will appear as pending until an administrator confirms it.',
        donation
      });
    }

    return res.status(400).json({ message: 'Unsupported payment method' });
  } catch (error) {
    console.error('Create donation error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const initiateEsewaDonation = async (req, res) => {
  try {
    const { donorName, donorEmail, amount, paymentMethod } = req.body;
    const amountValue = normalizeAmount(amount);

    if (!amountValue || amountValue <= 0) {
      return res.status(400).json({ message: 'Amount must be a positive number' });
    }

    const pmRaw = String(paymentMethod || 'esewa_wallet').toLowerCase();
    if (!isEsewaPaymentMethod(pmRaw)) {
      return res.status(400).json({ message: 'Invalid payment method for eSewa initiation' });
    }

    let candidateTransactionId = req.body.transactionId || buildEsewaTransactionId();
    let donation;

    const baseData = {
      ...donationUserData(req),
      donorName: donorName?.trim() || null,
      donorEmail: donorEmail?.trim() || null,
      amount: amountValue,
      paymentMethod: pmRaw === 'card' ? 'card' : 'esewa_wallet',
      transactionId: candidateTransactionId,
      status: 'pending',
      campaignId: req.body.campaignId ? parseInt(req.body.campaignId) : null
    };

    try {
      donation = await prisma.donation.create({
        data: baseData
      });
    } catch (error) {
      if (error.code === 'P2002') {
        candidateTransactionId = buildEsewaTransactionId();
        donation = await prisma.donation.create({
          data: { ...baseData, transactionId: candidateTransactionId }
        });
      } else {
        throw error;
      }
    }

    res.status(201).json({
      message: 'Esewa payment initialized',
      donation
    });
  } catch (error) {
    console.error('Initiate eSewa donation error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const confirmEsewaDonation = async (req, res) => {
  try {
    const {
      donationId,
      transactionCode,
      transactionUuid,
      status,
      responseData
    } = req.body;

    const id = parseInt(donationId);
    if (!id || Number.isNaN(id)) {
      return res.status(400).json({ message: 'Valid donationId is required' });
    }

    const finalStatus = normalizeStatus(status || 'completed');
    const donation = await prisma.donation.findUnique({ where: { donationId: id } });
    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    if (!isEsewaPaymentMethod(donation.paymentMethod)) {
      return res.status(400).json({ message: 'Donation is not an eSewa/card payment' });
    }

    const updatedDonation = await prisma.donation.update({
      where: { donationId: id },
      data: {
        status: finalStatus,
        transactionId: transactionCode || transactionUuid || donation.transactionId
      }
    });

    // If donation is completed and linked to a campaign, update campaign raisedAmount
    if (finalStatus === 'completed' && updatedDonation.campaignId) {
      await prisma.campaign.update({
        where: { campaignId: updatedDonation.campaignId },
        data: {
          raisedAmount: {
            increment: updatedDonation.amount
          }
        }
      });
    }

    res.json({
      message: 'Esewa donation confirmed',
      donation: updatedDonation,
      ...(responseData ? { responseData } : {})
    });
  } catch (error) {
    console.error('Confirm eSewa donation error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const failEsewaDonation = async (req, res) => {
  try {
    const { donationId } = req.body;
    const id = parseInt(donationId);
    if (!id || Number.isNaN(id)) {
      return res.status(400).json({ message: 'Valid donationId is required' });
    }

    const donation = await prisma.donation.findUnique({ where: { donationId: id } });
    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    const updatedDonation = await prisma.donation.update({
      where: { donationId: id },
      data: {
        status: 'failed'
      }
    });

    res.json({
      message: 'Esewa donation marked as failed',
      donation: updatedDonation
    });
  } catch (error) {
    console.error('Fail eSewa donation error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getDonations = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (status) where.status = status;

    const [donations, total] = await Promise.all([
      prisma.donation.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: { name: true, email: true }
          },
          campaign: {
            select: { campaignId: true, title: true }
          }
        }
      }),
      prisma.donation.count({ where })
    ]);

    res.json({
      donations,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get donations error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getMyDonations = async (req, res) => {
  try {
    const uid = req.user.userId;
    const email = req.user.email;
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = {
      OR: [
        { userId: uid },
        ...(email ? [{ donorEmail: email }] : [])
      ]
    };

    const [donations, total] = await Promise.all([
      prisma.donation.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { createdAt: 'desc' },
        include: {
          campaign: {
            select: {
              campaignId: true,
              title: true
            }
          }
        }
      }),
      prisma.donation.count({ where })
    ]);

    res.json({
      donations,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get my donations error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getDonationById = async (req, res) => {
  try {
    const { id } = req.params;
    const donationId = parseInt(id);

    const donation = await prisma.donation.findUnique({
      where: { donationId },
      include: {
        user: {
          select: { name: true, email: true }
        }
      }
    });

    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    const user = await prisma.user.findUnique({
      where: { userId: req.user.userId },
      include: { role: true }
    });

    const isAdmin = user?.role?.roleName === 'admin';
    const isOwner =
      donation.userId === req.user.userId ||
      (req.user.email && donation.donorEmail === req.user.email);

    if (!isAdmin && !isOwner) {
      return res.status(403).json({ message: 'Access denied' });
    }

    res.json({ donation });
  } catch (error) {
    console.error('Get donation by id error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
