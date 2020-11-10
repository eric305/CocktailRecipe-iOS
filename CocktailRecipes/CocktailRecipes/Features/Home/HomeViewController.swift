//
//  HomeViewController.swift
//  CocktailRecipes
//
//  Created by Eric Rado on 7/20/20.
//  Copyright © 2020 Eric Rado. All rights reserved.
//

import UIKit

final class HomeViewController: UICollectionViewController {

    private let presenter: HomePresenter
    private let numberOfRowsInSection = 5

    init(presenter: HomePresenter) {
        self.presenter = presenter
        super.init(collectionViewLayout: HomeViewController.makeLayout())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = .white

        collectionView.backgroundColor = .white
        collectionView.register(SmallDrinkCell.self, forCellWithReuseIdentifier: SmallDrinkCell.identifier)
        collectionView.register(LargeDrinkCell.self, forCellWithReuseIdentifier: LargeDrinkCell.identifier)
        collectionView.register(SectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: SectionHeader.identifier)

		presenter.delegate = self
	}

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.navigationBar.isHidden = false
    }

	private static func makeLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout { (sectionIndex, _) -> NSCollectionLayoutSection? in
			switch HomeSection.allCases[sectionIndex] {
			case .random:
				return HomeViewController.createFirstSectionLayout()
			case .latest, .popular:
				return HomeViewController.createThirdSectionLayout()
			}
		}

		let configuration = UICollectionViewCompositionalLayoutConfiguration()
		configuration.interSectionSpacing = 8
		layout.configuration = configuration
		return layout
	}
}

extension HomeViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		let sectionType = HomeSection.allCases[section]
        let counter = presenter.dataSource(for: sectionType).count
        return counter < numberOfRowsInSection ? counter : numberOfRowsInSection
	}

    override func collectionView(
		_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let sectionType = HomeSection.allCases[indexPath.section]
		let dataSource = presenter.dataSource(for: sectionType)
		let drink = dataSource[indexPath.row]

		switch sectionType {
		case .random:
			guard let cell = collectionView.dequeueReusableCell(
				withReuseIdentifier: LargeDrinkCell.identifier, for: indexPath) as? LargeDrinkCell else {
				return UICollectionViewCell()
			}
			cell.configure(image: nil, text: drink.name)
			return cell
		case .latest, .popular:
			guard let cell = collectionView.dequeueReusableCell(
				withReuseIdentifier: SmallDrinkCell.identifier, for: indexPath) as? SmallDrinkCell else {
				return UICollectionViewCell()
			}
			cell.configure(image: nil, text: drink.name, rank: nil)
			return cell
		}

	}

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return presenter.sectionCount
	}

    override func collectionView(
		_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
		at indexPath: IndexPath) -> UICollectionReusableView {
		guard let headerView = collectionView.dequeueReusableSupplementaryView(
			ofKind: UICollectionView.elementKindSectionHeader,
			withReuseIdentifier: SectionHeader.identifier,
			for: indexPath) as? SectionHeader else { fatalError("Could not dequeue SectionHeader") }
        headerView.configure(text: HomeSection.allCases[indexPath.section].title, sectionIndex: indexPath.section)
        headerView.delegate = self
		return headerView
	}
}

// MARK: - Compositional Layout Helpers
extension HomeViewController {
	private static func createSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
		let layoutSectionHeaderSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(1), heightDimension: .absolute(50))
		return NSCollectionLayoutBoundarySupplementaryItem(
			layoutSize: layoutSectionHeaderSize,
			elementKind: UICollectionView.elementKindSectionHeader,
			alignment: .top)
	}

	private static func createFirstSectionLayout() -> NSCollectionLayoutSection {
		let itemSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
		let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
		layoutItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)

		let groupSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(0.95), heightDimension: .estimated(250))
		let layoutGroup = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [layoutItem])

		let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
		layoutSection.orthogonalScrollingBehavior = .groupPagingCentered
		layoutSection.boundarySupplementaryItems = [createSectionHeader()]

		return layoutSection
	}

	private static func createSecondSectionLayout() -> NSCollectionLayoutSection {
		let itemSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(0.45), heightDimension: .fractionalHeight(0.5))
		let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
		layoutItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)

		let groupSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(0.95), heightDimension: .estimated(250))
		let layoutGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: layoutItem, count: 2)

		let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
		layoutSection.orthogonalScrollingBehavior = .groupPagingCentered
		layoutSection.boundarySupplementaryItems = [createSectionHeader()]

		return layoutSection
	}

	private static func createThirdSectionLayout() -> NSCollectionLayoutSection {
		let itemSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
		let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)

		let groupSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(1), heightDimension: .absolute(100))

		let layoutGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [layoutItem])
		let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
		layoutSection.boundarySupplementaryItems = [createSectionHeader()]
		return layoutSection
	}
}

extension HomeViewController: HomeViewDelegate {
	func reloadCollectionView(for section: Int) {
		collectionView.reloadSections(IndexSet(integer: section))
	}
}

extension HomeViewController: SectionHeaderDelegate {
    func didTapShowMoreForSectionHeader(_ sectionHeader: SectionHeader, sectionIndex: Int) {
        let sectionType = HomeSection.allCases[sectionIndex]
        let dataSource = presenter.dataSource(for: sectionType)

        let drinkListPresenter = DrinkListPresenter(drinks: dataSource)
        let drinkListViewController = DrinkListViewController(presenter: drinkListPresenter,
                                                                         title: sectionType.title)

        navigationController?.pushViewController(drinkListViewController, animated: true)
    }
}
