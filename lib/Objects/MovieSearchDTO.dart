class MovieSearchDTO {
  final String id;
  final String title;
  final String posterPath;
  final List<String> genres;
  int movieRate;
  final int year;

  MovieSearchDTO({this.id, this.title, this.posterPath,
    this.genres, this.movieRate,this.year, });

  factory MovieSearchDTO.fromJson(Map<String, dynamic> json) {
    return MovieSearchDTO(
        id: json['id'],
        title: json['title'],
        posterPath: json['posterPath'],
//        genres: json['genres'].cast<String>(),
        year: json['year'],
//        movieRate: json['movieRate'],
    );
  }
}