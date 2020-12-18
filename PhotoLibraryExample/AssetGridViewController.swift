//
//  AssetGridViewController.swift
//  PhotoLibraryExample
//
//  Created by Sakdinan Sukkhasem on 18/12/20.
//

import UIKit
import Photos
import PhotosUI // import for presentLimitedLibraryPicker

class AssetGridViewController: UIViewController {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    private var fetchResult: PHFetchResult<PHAsset>!
    private let imageManager = PHCachingImageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Photo Gallary"
        imageManager.stopCachingImagesForAllAssets()
        PHPhotoLibrary.shared().register(self)
        collectionView.register(GridViewCell.self, forCellWithReuseIdentifier: GridViewCell.identifier)
        fetchAssets()
        authorization()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    private func fetchAssets() {
        fetchResult = PHAsset.fetchAssets(with: PHFetchOptions())
    }
    
    private func authorization() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        debugPrint("Authorization status: \(status)")
        switch status {
        case .authorized:
            DispatchQueue.main.async {
                self.fetchAssets()
                self.collectionView.reloadData()
                self.collectionView.scrollToItem(at: IndexPath(item: self.fetchResult.count-1, section: 0),
                                                 at: .bottom,
                                                 animated: false)
            }
        default: break
        }
    }
    
    // MARK: Action
    @IBAction private func addImages(_ sender: UIBarButtonItem) {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized:
            PHPhotoLibrary.shared().performChanges {
                let image = UIImage.randomImageColor()
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        case .limited:
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
        default: break
        }
    }
}

// MARK: - UICollectionViewDataSource
extension AssetGridViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fetchResult.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GridViewCell.identifier, for: indexPath) as! GridViewCell
        let asset = fetchResult.object(at: indexPath.row)
        imageManager.requestImage(for: asset, targetSize: cell.frame.size, contentMode: .aspectFill, options: nil) { (image, _) in
            cell.backgroundView = UIImageView(image: image)
        }
        return cell
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension AssetGridViewController: PHPhotoLibraryChangeObserver {
    // do every time select more or change image selected
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: fetchResult) else { return }
        // 2
        fetchResult = changes.fetchResultAfterChanges
        // 3
        DispatchQueue.main.async {
            // hasIncrementalChanges is false when limited access photos
            if changes.hasIncrementalChanges {
                self.updateCollectionView(changes)
            } else {
                self.collectionView.reloadData()
            }
        }
    }
    
    private func updateCollectionView(_ changes: PHFetchResultChangeDetails<PHAsset>) {
        // Batch update.
        self.collectionView.performBatchUpdates {
            // Handle removals
            if let removed = changes.removedIndexes,
               !removed.isEmpty {
                self.collectionView.deleteItems(at: removed.map { IndexPath(item: $0, section: 0) })
            }
            
            // Handle insertions
            if let inserted = changes.insertedIndexes,
               !inserted.isEmpty {
                self.collectionView.insertItems(at: inserted.map { IndexPath(item: $0, section: 0) })
            }
            
            // Handle moves
            changes.enumerateMoves { (fromIndex, toIndex) in
                self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                             to: IndexPath(item: toIndex, section: 0))
            }
        }
        // Reloading items after the batch update since `PHFetchResultChangeDetails.changedIndexes` refers to
        // items in the *after* state and not the *before* state as expected by `performBatchUpdates(_:completion:)`
        if let changed = changes.changedIndexes,
           !changed.isEmpty {
            self.collectionView.reloadItems(at: changed.map { IndexPath(item: $0, section: 0) })
        }
    }
}
// handle collection view
// MARK: - UICollectionViewDelegateFlowLayout
extension AssetGridViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let imagePerRow: CGFloat = 3
        let numberOfSeperator: CGFloat = imagePerRow - 1
        let width: CGFloat = (UIScreen.main.bounds.width - numberOfSeperator) / imagePerRow
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }
}
