/*
 * Copyright (C) 2016 nohana, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import Photos

public class PhotoKitAlbumList: ItemList {

    private var albumList: [Item] = []
    private let assetCollectionTypes: [PHAssetCollectionType]
    private let assetCollectionSubtypes: [PHAssetCollectionSubtype]
    private let mediaType: MediaType
    private var shouldShowEmptyAlbum: Bool
    var offset: Int?
    var limit: Int?

    // MARK: - init

    init(assetCollectionTypes: [PHAssetCollectionType], assetCollectionSubtypes: [PHAssetCollectionSubtype], mediaType: MediaType, shouldShowEmptyAlbum: Bool, handler:(() -> Void)?) {
        self.assetCollectionTypes = assetCollectionTypes
        self.assetCollectionSubtypes = assetCollectionSubtypes
        self.mediaType = mediaType
        self.shouldShowEmptyAlbum = shouldShowEmptyAlbum
        update { () -> Void in
            if let handler = handler {
                handler()
            }
        }
    }

    // MARK: - ItemList

    public typealias Item = PhotoKitAssetList

    open var title: String {
        return "PhotoKit"
    }
    
    open func totalSectionsCountForMoments() -> Int {
        let albumListFetchResult: [PHFetchResult<PHAssetCollection>] = [PHAssetCollection.fetchAssetCollections(with: .moment, subtype: .any, options: nil)]
        return albumListFetchResult.first?.count ?? 0
    }

    open func update(_ handler:(() -> Void)?) {
        DispatchQueue.global(qos: .default).async {
            var albumListFetchResult: [PHFetchResult<PHAssetCollection>] = []
            for type in self.assetCollectionTypes {
                albumListFetchResult = albumListFetchResult + [PHAssetCollection.fetchAssetCollections(with: type, subtype: .any, options: nil)]
            }

            var tmpAlbumList: [Item] = []
            let isAssetCollectionSubtypeAny = self.assetCollectionSubtypes.contains(.any)
            
            if self.assetCollectionTypes == [.moment] {
                for fetchResult in albumListFetchResult {
                    var albums: [PHAssetCollection] = []
                    fetchResult.enumerateObjects { (album, index, stop) in
                        albums.append(album)
                    }
                    albums = albums.sorted { $0.startDate!.timeIntervalSince1970 < $1.startDate!.timeIntervalSince1970 }
                    albums.reverse()
                    if self.offset == nil {
                        self.offset = 0
                    } else {
                        self.offset! += 20
                    }
                    let limit = (self.offset ?? 0) + (self.limit ?? 20)
                    let albumsByIndex = albums[(self.offset ?? 0)..<limit]
                    for album in albumsByIndex {
                        if self.assetCollectionSubtypes.contains(album.assetCollectionSubtype) || isAssetCollectionSubtypeAny {
                            if self.shouldShowEmptyAlbum || PHAsset.fetchAssets(in: album, options: PhotoKitAssetList.fetchOptions(self.mediaType)).count != 0 {
                                tmpAlbumList.append(PhotoKitAssetList(album: album, mediaType: self.mediaType))
                            }
                        }
                    }
                }
            } else {
                self.albumList = []
                for fetchResult in albumListFetchResult {
                    fetchResult.enumerateObjects({ (album, index, stop) in
                        if self.assetCollectionSubtypes.contains(album.assetCollectionSubtype) || isAssetCollectionSubtypeAny {
                            if self.shouldShowEmptyAlbum || PHAsset.fetchAssets(in: album, options: PhotoKitAssetList.fetchOptions(self.mediaType)).count != 0 {
                                tmpAlbumList.append(PhotoKitAssetList(album: album, mediaType: self.mediaType, forAlbumGalery: true))
                            }
                        }
                    })
                }
            }
            if self.assetCollectionTypes == [.moment] {
                self.albumList.append(contentsOf: tmpAlbumList)
            } else {
                self.albumList =  tmpAlbumList
            }

            if let handler = handler {
                handler()
            }
        }
    }

    open subscript (index: Int) -> Item {
        return albumList[index] as Item
    }

    // MARK: - CollectionType

    open var startIndex: Int {
        return albumList.startIndex
    }

    open var endIndex: Int {
        return albumList.endIndex
    }

}
