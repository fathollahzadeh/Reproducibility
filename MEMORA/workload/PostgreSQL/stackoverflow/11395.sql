WITH PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM Votes
    GROUP BY PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
)

SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.Score,
    P.ViewCount,
    COALESCE(U.DisplayName, 'Community User') AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    COALESCE(PVC.Upvotes, 0) AS UpvoteCount,
    COALESCE(PVC.Downvotes, 0) AS DownvoteCount,
    COALESCE(UB.BadgeCount, 0) AS OwnerBadgeCount
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    PostVoteCounts PVC ON P.Id = PVC.PostId
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
WHERE 
    P.CreationDate >= '2023-01-01' 
ORDER BY 
    P.CreationDate DESC
LIMIT 100;