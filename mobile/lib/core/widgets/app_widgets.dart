import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        width: width,
        height: height ?? 50,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const CircularProgressIndicator()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(text),
                  ],
                ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height ?? 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CircularProgressIndicator()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final int? maxLines;
  final IconData? prefixIcon;

  const AppTextField({
    super.key,
    required this.labelText,
    this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLines: maxLines,
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const AppCard({super.key, required this.child, this.margin, this.padding, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      margin: margin ?? const EdgeInsets.all(8.0),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}

class AppListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leadingIcon != null ? Icon(leadingIcon) : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class AppLoadingIndicator extends StatelessWidget {
  final String? message;

  const AppLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[const SizedBox(height: 16), Text(message!)],
        ],
      ),
    );
  }
}

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionText;

  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onAction, child: Text(actionText!)),
          ],
        ],
      ),
    );
  }
}
