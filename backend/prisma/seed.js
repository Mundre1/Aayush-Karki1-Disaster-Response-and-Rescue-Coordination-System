import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();
const SEED_PASSWORD = 'password123';
const startDate = new Date('2026-01-24T08:00:00.000Z');
const now = new Date();

function mulberry32(a) {
  return function seeded() {
    let t = (a += 0x6D2B79F5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const rand = mulberry32(20260124);
const randomInt = (min, max) => Math.floor(rand() * (max - min + 1)) + min;
const pick = (arr) => arr[randomInt(0, arr.length - 1)];
const randomDate = (from, to) =>
  new Date(from.getTime() + rand() * (to.getTime() - from.getTime()));

const incidentImage = (id) => `https://picsum.photos/seed/nepal-incident-${id}/1200/800`;
const updateImage = (id) => `https://picsum.photos/seed/nepal-update-${id}/1000/700`;
const campaignImage = (id) => `https://picsum.photos/seed/nepal-campaign-${id}/1200/700`;

async function clearDatabase() {
  console.log('🧹 Clearing existing data...');
  await prisma.comment.deleteMany();
  await prisma.notification.deleteMany();
  await prisma.incidentUpdate.deleteMany();
  await prisma.volunteerMissionRequest.deleteMany();
  await prisma.mission.deleteMany();
  await prisma.incident.deleteMany();
  await prisma.location.deleteMany();
  await prisma.donation.deleteMany();
  await prisma.campaign.deleteMany();
  await prisma.volunteer.deleteMany();
  await prisma.user.deleteMany();
  await prisma.organization.deleteMany();
  await prisma.role.deleteMany();
}

async function main() {
  console.log('🌱 Starting rich Nepal seed...');
  await clearDatabase();

  const hashed = await bcrypt.hash(SEED_PASSWORD, 10);

  const [adminRole, citizenRole, volunteerRole, responderRole] = await Promise.all([
    prisma.role.create({ data: { roleName: 'admin' } }),
    prisma.role.create({ data: { roleName: 'citizen' } }),
    prisma.role.create({ data: { roleName: 'volunteer' } }),
    prisma.role.create({ data: { roleName: 'responder' } })
  ]);

  const organizationsPayload = [
    ['Nepal Police Disaster Response Unit', 'Urban rescue, crowd safety, traffic control', '+977-1-4410000'],
    ['Nepal Army Rapid Action Force', 'Heavy rescue, logistics, evacuation', '+977-1-4220000'],
    ['Nepal Red Cross Emergency Medical Team', 'Emergency medicine, blood support, first aid', '+977-1-4270650'],
    ['Kathmandu Fire and Rescue Brigade', 'Fire control, collapse rescue, hazardous response', '+977-1-4221155'],
    ['Armed Police Force Flood Rescue Wing', 'Swift water rescue, flood evacuation', '+977-1-4283000'],
    ['Pokhara Metropolitan Search and Rescue', 'Landslide response, mountain search', '+977-61-460100']
  ];

  const organizations = [];
  for (const [name, specialization, contact] of organizationsPayload) {
    organizations.push(
      await prisma.organization.create({
        data: {
          organizationName: name,
          specialization,
          contact,
          approvalStatus: 'approved',
          isActive: true
        }
      })
    );
  }

  const adminNames = ['Sagar Adhikari', 'Nirajan Bhandari', 'Mina KC'];
  const citizenNames = [
    'Rabin Thapa', 'Sujata Koirala', 'Purna Rai', 'Anjana Shrestha', 'Kamal Basnet',
    'Roshani Tamang', 'Dipesh Gurung', 'Sabina Maharjan', 'Ashok Karki', 'Sneha Lama',
    'Krishna Poudel', 'Mamata Bhattarai', 'Ramesh Khadka', 'Binita Rai', 'Prakash Oli',
    'Sangita Parajuli', 'Milan Chaudhary', 'Kabita Magar'
  ];
  const volunteerNames = [
    'Bijay Subedi', 'Nisha Gurung', 'Aayush Kandel', 'Pabitra Rai',
    'Samir Ghimire', 'Rekha Bista', 'Sudip Bohora', 'Kalpana Tamang',
    'Dhiraj Oli', 'Sunita Dahal', 'Prabin Luitel', 'Rita Pun'
  ];
  const responderNames = [
    'Captain Rajesh Sharma', 'Officer Sunita Basnet', 'Medic Bikash Thapa', 'Firefighter Rabin Magar',
    'Inspector Alina Kunwar', 'Lieutenant Prakash Shah', 'Paramedic Roshan Khatri', 'Rescuer Suman Gurung',
    'Sub-Inspector Nabin Bhandari', 'Sergeant Sushila Ale', 'Medic Keshav Adhikari', 'Fire Officer Jenisha Rai'
  ];

  const users = [];
  let phoneSuffix = 1000000;
  const mkEmail = (name, domain) => `${name.toLowerCase().replace(/\s+/g, '.')}@${domain}`;

  for (const n of adminNames) {
    users.push(
      await prisma.user.create({
        data: {
          name: n,
          email: mkEmail(n, 'disasterresponse.gov.np'),
          password: hashed,
          phone: `+977-98${phoneSuffix++}`,
          roleId: adminRole.roleId
        }
      })
    );
  }
  users.push(
    await prisma.user.create({
      data: {
        name: 'Ayush Ghimire',
        email: 'np05cp4a230218@iic.edu.np',
        password: hashed,
        phone: `+977-98${phoneSuffix++}`,
        roleId: adminRole.roleId
      }
    })
  );

  const citizenUsers = [];
  for (const n of citizenNames) {
    const u = await prisma.user.create({
      data: {
        name: n,
        email: mkEmail(n, 'gmail.com'),
        password: hashed,
        phone: `+977-98${phoneSuffix++}`,
        roleId: citizenRole.roleId
      }
    });
    users.push(u);
    citizenUsers.push(u);
  }

  const volunteerUsers = [];
  for (const n of volunteerNames) {
    const u = await prisma.user.create({
      data: {
        name: n,
        email: mkEmail(n, 'volunteer.org.np'),
        password: hashed,
        phone: `+977-98${phoneSuffix++}`,
        roleId: volunteerRole.roleId
      }
    });
    users.push(u);
    volunteerUsers.push(u);
  }

  const responderUsers = [];
  for (let i = 0; i < responderNames.length; i += 1) {
    const org = organizations[i % organizations.length];
    const u = await prisma.user.create({
      data: {
        name: responderNames[i],
        email: mkEmail(responderNames[i], 'responder.gov.np'),
        password: hashed,
        phone: `+977-98${phoneSuffix++}`,
        roleId: responderRole.roleId,
        organizationId: org.organizationId,
        responderStatus: 'approved'
      }
    });
    users.push(u);
    responderUsers.push(u);
  }

  const skills = [
    'First aid, evacuation support, camp coordination',
    'Search support, relief logistics, crowd communication',
    'Medical triage, patient transport, psychosocial support',
    'Food distribution, water support, shelter setup'
  ];
  for (let i = 0; i < volunteerUsers.length; i += 1) {
    await prisma.volunteer.create({
      data: {
        userId: volunteerUsers[i].userId,
        skills: skills[i % skills.length],
        availability: pick(['available', 'available', 'busy']),
        isApproved: true
      }
    });
  }

  const nepalLocations = [
    ['Thamel, Kathmandu', 'Kathmandu', 27.7172, 85.3240],
    ['Kalimati, Kathmandu', 'Kathmandu', 27.6937, 85.3001],
    ['Bouddha, Kathmandu', 'Kathmandu', 27.7215, 85.3620],
    ['Patan Durbar Area, Lalitpur', 'Lalitpur', 27.6729, 85.3257],
    ['Bhaktapur Durbar Square', 'Bhaktapur', 27.6710, 85.4298],
    ['Banepa Bazar', 'Kavrepalanchok', 27.6298, 85.5210],
    ['Damauli Highway Stretch', 'Tanahun', 27.9833, 84.2667],
    ['Lakeside, Pokhara', 'Kaski', 28.2096, 83.9856],
    ['Sarangkot Access Road', 'Kaski', 28.2450, 83.9480],
    ['Bharatpur Bypass', 'Chitwan', 27.6766, 84.4304],
    ['Sauraha, Chitwan', 'Chitwan', 27.5830, 84.4980],
    ['Butwal Chowk', 'Rupandehi', 27.7000, 83.4500],
    ['Tansen Hill Road', 'Palpa', 27.8670, 83.5460],
    ['Dharan Main Road', 'Sunsari', 26.8120, 87.2830],
    ['Biratnagar Industrial Area', 'Morang', 26.4525, 87.2718],
    ['Janakpur Bus Park', 'Dhanusha', 26.7288, 85.9250],
    ['Hetauda Riverbank', 'Makwanpur', 27.4280, 85.0322],
    ['Nepalgunj Bazar', 'Banke', 28.0500, 81.6167],
    ['Dhangadhi Main Corridor', 'Kailali', 28.7000, 80.6000],
    ['Besisahar Town Area', 'Lamjung', 28.2333, 84.3667]
  ];

  const locations = [];
  for (const [address, district, latitude, longitude] of nepalLocations) {
    locations.push(await prisma.location.create({ data: { address, district, latitude, longitude } }));
  }

  const incidentTitles = [
    'Road traffic collision',
    'Landslide blocking highway',
    'Flash flood entering settlement',
    'House fire in residential block',
    'Electric short-circuit fire',
    'Tree collapse on vehicles',
    'Bridge approach erosion',
    'Bus rollover on hilly road',
    'Wall collapse after heavy rain',
    'Medical emergency in public area'
  ];
  const incidentDescriptions = [
    'Multiple injured reported at scene. Immediate rescue and traffic diversion needed.',
    'Debris has blocked lane access and trapped several passengers in nearby vehicles.',
    'Water level rose rapidly, families are relocating from low-lying area.',
    'Smoke visible from upper floors; residents requesting urgent evacuation support.',
    'Power supply unstable and nearby shops affected by sparks and smoke.',
    'Strong winds caused trees to fall and obstruct emergency mobility.',
    'Riverbank erosion threatening nearby homes and transport routes.',
    'Rescue required for injured occupants with crowd and traffic control.',
    'Structure damage reported with risk of secondary collapse.',
    'One critical patient and several bystanders requesting immediate help.'
  ];
  const severities = ['low', 'medium', 'high', 'critical'];
  const statuses = ['pending', 'verified', 'assigned', 'in_progress', 'resolved', 'closed'];

  const incidents = [];
  const missions = [];
  const allComments = [];
  const allUpdates = [];
  const allNotifications = [];
  let imageSeed = 1;

  const incidentCount = 90;
  for (let i = 0; i < incidentCount; i += 1) {
    const reporter = pick(citizenUsers);
    const location = pick(locations);
    const reportedAt = randomDate(startDate, now);
    const status = pick(statuses);
    const severity = pick(severities);
    const title = pick(incidentTitles);
    const description = pick(incidentDescriptions);

    const incident = await prisma.incident.create({
      data: {
        userId: reporter.userId,
        locationId: location.locationId,
        title,
        description,
        severity,
        status,
        imageUrl: incidentImage(imageSeed++),
        reportedAt
      }
    });
    incidents.push(incident);

    const updatesPerIncident = randomInt(3, 7);
    for (let u = 0; u < updatesPerIncident; u += 1) {
      const actor = pick([...users.slice(0, 3), ...responderUsers, reporter]);
      const st = pick(['pending', 'verified', 'assigned', 'in_progress', 'resolved']);
      const updateTime = new Date(reportedAt.getTime() + (u + 1) * 60 * 60 * 1000);
      const note = pick([
        'Field verification completed; risk level recalibrated.',
        'Evacuation started for households within immediate danger zone.',
        'Responder team reached location and started primary assessment.',
        'Medical support deployed and temporary aid point established.',
        'Traffic diversion and perimeter control underway.',
        'Situation stabilizing; follow-up monitoring in progress.'
      ]);
      allUpdates.push(
        prisma.incidentUpdate.create({
          data: {
            incidentId: incident.incidentId,
            userId: actor.userId,
            status: st,
            note,
            imageUrl: rand() > 0.45 ? updateImage(imageSeed++) : null,
            updatedAt: updateTime
          }
        })
      );
    }

    if (['assigned', 'in_progress', 'resolved', 'closed'].includes(status)) {
      const org = pick(organizations);
      const member = pick(responderUsers.filter((r) => r.organizationId === org.organizationId));
      const missionStatus = status === 'assigned' ? 'assigned' : status === 'in_progress' ? 'in_progress' : 'completed';
      const mission = await prisma.mission.create({
        data: {
          incidentId: incident.incidentId,
          organizationId: org.organizationId,
          userId: member?.userId ?? null,
          missionStatus,
          assignedAt: new Date(reportedAt.getTime() + 45 * 60 * 1000),
          completedAt: missionStatus === 'completed' ? new Date(reportedAt.getTime() + 8 * 60 * 60 * 1000) : null
        }
      });
      missions.push(mission);
      allNotifications.push(
        prisma.notification.create({
          data: {
            userId: reporter.userId,
            incidentId: incident.incidentId,
            type: 'status_update',
            message: `${org.organizationName} assigned to your reported incident.`,
            isRead: rand() > 0.5
          }
        })
      );
    }

    const commentsPerIncident = randomInt(5, 10);
    for (let c = 0; c < commentsPerIncident; c += 1) {
      const author = pick([...citizenUsers, ...volunteerUsers, ...responderUsers, ...users.slice(0, 3)]);
      const text = pick([
        'Nearby community volunteers are organizing first-aid support.',
        'Please avoid the affected road and use alternate route.',
        'Ambulance has departed from municipal post and ETA is 12 minutes.',
        'Water level is still rising in southern lane; keep children indoors.',
        'We have provided temporary shelter materials to three families.',
        'Rescue team requested additional lighting for night operation.',
        'Local ward office coordinating food packets and drinking water.',
        'Situation is under control but monitoring remains active.'
      ]);
      const createdAt = new Date(reportedAt.getTime() + randomInt(30, 720) * 60 * 1000);
      allComments.push(
        prisma.comment.create({
          data: {
            incidentId: incident.incidentId,
            userId: author.userId,
            content: text,
            createdAt
          }
        })
      );
    }
  }

  await Promise.all(allUpdates);
  await Promise.all(allComments);

  const campaignTitles = [
    'Flood Relief for Koshi Corridor Families',
    'Emergency Shelter Support for Landslide Survivors',
    'Medical Aid and Blood Support Drive',
    'Winter Relief Kits for Mountain Villages',
    'School Recovery After Local Disaster',
    'Fire Victim Household Rebuilding Fund',
    'Roadside Trauma Care Equipment Support',
    'Women and Child Safety Recovery Program'
  ];

  const campaigns = [];
  for (let i = 0; i < 24; i += 1) {
    const creator = pick([...citizenUsers, ...volunteerUsers, ...users.slice(0, 3)]);
    const targetAmount = randomInt(80000, 850000);
    const status = pick(['pending', 'approved', 'approved', 'approved', 'rejected', 'completed']);
    let raisedAmount = 0;
    if (status === 'completed') raisedAmount = targetAmount;
    if (status === 'approved') raisedAmount = randomInt(Math.floor(targetAmount * 0.15), Math.floor(targetAmount * 0.95));
    if (status === 'pending') raisedAmount = randomInt(0, Math.floor(targetAmount * 0.2));

    campaigns.push(
      await prisma.campaign.create({
        data: {
          creatorId: creator.userId,
          title: `${pick(campaignTitles)} #${i + 1}`,
          description: 'Community-led fundraiser focused on verified local needs and transparent utilization.',
          targetAmount,
          raisedAmount,
          imageUrl: campaignImage(imageSeed++),
          status,
          createdAt: randomDate(startDate, now)
        }
      })
    );
  }

  const paymentMethods = ['esewa', 'bank_transfer', 'cash', 'khalti'];
  const donations = [];
  for (let i = 0; i < 260; i += 1) {
    const donor = rand() > 0.25 ? pick([...citizenUsers, ...volunteerUsers]) : null;
    const campaign = rand() > 0.15 ? pick(campaigns) : null;
    const amount = randomInt(500, 30000);
    const status = pick(['completed', 'completed', 'completed', 'pending', 'failed']);
    const createdAt = randomDate(startDate, now);
    donations.push(
      prisma.donation.create({
        data: {
          userId: donor?.userId ?? null,
          campaignId: campaign?.campaignId ?? null,
          donorName: donor?.name ?? pick(citizenNames),
          donorEmail: donor?.email ?? `${pick(['help', 'donor', 'support'])}${i}@mail.com`,
          amount,
          paymentMethod: pick(paymentMethods),
          transactionId: `TXN-2026-${String(i + 1).padStart(5, '0')}`,
          status,
          createdAt
        }
      })
    );
  }
  await Promise.all(donations);

  for (const c of campaigns) {
    const sums = await prisma.donation.aggregate({
      where: { campaignId: c.campaignId, status: 'completed' },
      _sum: { amount: true }
    });
    const raised = Number(sums._sum.amount || 0);
    const status = raised >= Number(c.targetAmount) ? 'completed' : c.status === 'rejected' ? 'rejected' : c.status;
    await prisma.campaign.update({
      where: { campaignId: c.campaignId },
      data: {
        raisedAmount: raised,
        status
      }
    });
  }

  for (const a of users.slice(0, 3)) {
    for (let i = 0; i < 25; i += 1) {
      allNotifications.push(
        prisma.notification.create({
          data: {
            userId: a.userId,
            incidentId: pick(incidents).incidentId,
            type: pick(['incident_reported', 'mission_assigned', 'status_update']),
            message: pick([
              'New high-priority incident reported in your monitoring area.',
              'Responder organization assigned and mission updated.',
              'Public status updated; ensure follow-up communication.',
              'Resource requirement escalation flagged by field responder.'
            ]),
            isRead: rand() > 0.4
          }
        })
      );
    }
  }
  await Promise.all(allNotifications);

  console.log('✅ Rich seed completed.');
  console.log(`👥 Users: ${users.length}`);
  console.log(`🚨 Incidents: ${incidents.length}`);
  console.log(`🎯 Missions: ${missions.length}`);
  console.log(`💬 Comments: ${allComments.length}`);
  console.log(`🧾 History updates: ${allUpdates.length}`);
  console.log(`🎗️ Campaigns: ${campaigns.length}`);
  console.log(`💰 Donations: ${donations.length}`);
  console.log('\n🔑 Default password for all seeded users: password123');
  console.log('Example logins:');
  console.log(`- Admin: ${mkEmail(adminNames[0], 'disasterresponse.gov.np')}`);
  console.log(`- Citizen: ${mkEmail(citizenNames[0], 'gmail.com')}`);
  console.log(`- Volunteer: ${mkEmail(volunteerNames[0], 'volunteer.org.np')}`);
  console.log(`- Responder: ${mkEmail(responderNames[0], 'responder.gov.np')}`);
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
