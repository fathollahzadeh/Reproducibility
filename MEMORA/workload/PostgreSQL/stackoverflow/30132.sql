WITH RecursiveUserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        p.Id AS PostId,
        p.CreationDate,
        p.Score,
        p.Title,
        p.Body,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS rn
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) AS c ON p.Id = c.PostId
    WHERE u.Reputation > 1000 
),
NestedComments AS (
    SELECT 
        p.Id AS PostId,
        c.UserDisplayName,
        c.Text,
        c.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY c.CreationDate DESC) AS CommentRank
    FROM Posts p
    JOIN Comments c ON p.Id = c.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoricalRecords
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId, ph.UserDisplayName, ph.CreationDate
)
SELECT 
    rup.UserId,
    rup.DisplayName,
    rup.PostId,
    rup.Title,
    rup.Score,
    rup.CommentCount,
    nc.UserDisplayName AS LastCommenter,
    nc.Text AS LastComment,
    phd.HistoryTypes,
    phd.HistoricalRecords
FROM RecursiveUserPosts rup
LEFT JOIN NestedComments nc ON rup.PostId = nc.PostId AND nc.CommentRank = 1 
LEFT JOIN PostHistoryDetails phd ON rup.PostId = phd.PostId
WHERE rup.rn <= 10  
ORDER BY rup.UserId, rup.CreationDate DESC;