import 'package:flutter/material.dart';

class DownloadOverviewPage extends StatefulWidget {
  const DownloadOverviewPage({super.key});

  @override
  State<DownloadOverviewPage> createState() => _DownloadOverviewPage();
}

class _DownloadOverviewPage extends State<DownloadOverviewPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF122C34)
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text("Download Overview"),
          centerTitle: true,
        ),
        body: const Center(
          child: Text("Download Overview Page"),
        ),
      ),
    );
  }
}