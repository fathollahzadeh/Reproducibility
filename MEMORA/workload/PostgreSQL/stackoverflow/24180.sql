WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate < cast('2024-10-01 12:34:56' as timestamp) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        pt.Name AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON pt.Id = ph.PostHistoryTypeId
)

SELECT 
    up.DisplayName,
    up.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    up.TotalBadges,
    rp.Upvotes,
    rp.Downvotes,
    (
        SELECT STRING_AGG(HT.HistoryType, ', ') 
        FROM PostHistoryDetails HT 
        WHERE HT.PostId = rp.PostId AND HT.HistoryRank <= 5 
    ) AS RecentHistoryTypes,
    LEAD(rp.Score, 1) OVER (ORDER BY rp.CreationDate) AS NextPostScore,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        WHEN rp.Score = 0 THEN 'Neutral'
        WHEN rp.Score > 0 THEN 'Positive'
        ELSE 'Negative' 
    END AS ScoreCategory,
    ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS GlobalRank
FROM 
    RankedPosts rp
JOIN 
    UserReputation up ON up.UserId = rp.OwnerUserId
WHERE 
    up.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND rp.Rank = 1 
ORDER BY 
    rp.Score DESC, up.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;