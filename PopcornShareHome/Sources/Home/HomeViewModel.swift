//
//  HomeViewModel.swift
//  PopcornShareHome
//
//  Created by Paulo Lazarini on 29/01/25.
//

import SwiftUI

import PopcornShareUtilities
import PopcornShareNetworkModel
import PopcornShareNetworkCore
import PopcornShareNetwork

enum MovieCategory: CaseIterable {
    case popular, topRated, nowPlaying, upcoming
    
    var title: String {
        switch self {
        case .popular:
            "Popular Movies"
        case .topRated:
            "Top Rated"
        case .nowPlaying:
            "Now Playing"
        case .upcoming:
            "Upcoming"
        }
    }
}

public final class HomeViewModel: ObservableObject, @unchecked Sendable {
    @Published var headerMovies: [MovieViewData] = []
    @Published var popularMovies: [MovieViewData] = []
    @Published var topRatedMovies: [MovieViewData] = []
    @Published var upcomingMovies: [MovieViewData] = []
    @Published var nowPlayingMovies: [MovieViewData] = []

    private let serviceManager: NetworkManagerType

    public init(serviceManager: NetworkManagerType = NetworkManager()) {
        self.serviceManager = serviceManager
    }
    
    func fetchMovies(
        type: MovieCategory,
        page: Int = 1
    ) async -> [MovieViewData]? {
        let result: Result<Movies, RequestError>
        
        switch type {
        case .popular:
            result = await serviceManager.getPopularMovies(page: page)
        case .topRated:
            result = await serviceManager.getTopRatedMovies(page: page)
        case .nowPlaying:
            result = await serviceManager.getNowPlayingMovies(page: page)
        case .upcoming:
            result = await serviceManager.getUpcomingMovies(page: page)
        }
        
        switch result {
        case .success(let movies):
            return movies.results.map { $0.toMovieViewData }
        case .failure(let error):
            print("Error fetching \(type): \(error)")
            return nil
        }
    }
    
    func fetchMovies() async {
        async let popularMovies = fetchMovies(type: .popular)
        async let topRatedMovies = fetchMovies(type: .topRated)
        async let nowPlayingMovies = fetchMovies(type: .nowPlaying)
        async let upcomingMovies = fetchMovies(type: .upcoming)
        
        let (popular, topRated, nowPlaying, upcoming) = await (
            popularMovies,
            topRatedMovies,
            nowPlayingMovies,
            upcomingMovies
        )

        await MainActor.run {
            if let popular = popular {
                self.popularMovies = popular
                self.headerMovies = Array(popular.prefix(5))
            }
            
            if let topRated = topRated {
                self.topRatedMovies = topRated
            }
            
            if let nowPlaying = nowPlaying {
                self.nowPlayingMovies = nowPlaying
            }
            
            if let upcoming = upcoming {
                self.upcomingMovies = upcoming
            }
        }
    }
}
