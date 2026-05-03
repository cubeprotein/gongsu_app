import 'package:flutter/material.dart';

class BoardListScreen extends StatelessWidget {
  const BoardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구인구직 게시판'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: 필터 기능 (지역, 직종, 단가) 연결
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 10, // 테스트용 데이터 개수
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text('[울산/배관] 단가 23만 - OOO 플랜트'),
              subtitle: const Text('야간 고정 / 숙소 제공 / 즉시 투입 가능'),
              trailing: const Text('방금 전', style: TextStyle(fontSize: 12)),
              onTap: () {
                // TODO: 상세 페이지 이동
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 글쓰기 페이지 이동
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
