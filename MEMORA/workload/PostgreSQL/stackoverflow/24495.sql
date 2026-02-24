WITH UserReputation AS (
    SELECT 
        Id as UserId, 
        Reputation,
        CASE 
            WHEN Reputation >= 100000 THEN 'Platinum'
            WHEN Reputation >= 50000 THEN 'Gold'
            WHEN Reputation >= 10000 THEN 'Silver'
            ELSE 'Bronze'
        END as BadgeType
    FROM Users
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) as EditRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)
),
CombinedData AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate as PostCreationDate,
        u.DisplayName as OwnerDisplayName,
        u.Reputation as OwnerReputation,
        ue.BadgeType,
        re.EditRank,
        COALESCE(c.Text, 'No comments') AS LatestComment,
        COALESCE(v.TotalVotes, 0) AS TotalVotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UserReputation ue ON u.Id = ue.UserId
    LEFT JOIN RecentEdits re ON p.Id = re.PostId AND re.EditRank = 1
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS TotalVotes 
        FROM Votes 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId AND c.CreationDate = (
        SELECT MAX(cc.CreationDate) FROM Comments cc WHERE cc.PostId = p.Id
    )
    WHERE p.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    cd.PostId, 
    cd.Title, 
    cd.PostCreationDate, 
    cd.OwnerDisplayName, 
    cd.OwnerReputation,
    cd.BadgeType,
    COALESCE(cd.LatestComment, 'This post has no comments') as LatestPostComment,
    cd.EditRank,
    (SELECT COUNT(DISTINCT pl.RelatedPostId) 
     FROM PostLinks pl 
     WHERE pl.PostId = cd.PostId) as RelatedPostCount
FROM CombinedData cd
WHERE cd.OwnerReputation IS NOT NULL
ORDER BY cd.OwnerReputation DESC, cd.EditRank DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;