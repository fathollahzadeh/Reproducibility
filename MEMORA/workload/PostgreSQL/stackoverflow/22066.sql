
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Date >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
    GROUP BY 
        u.Id
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.Score,
        ub.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        UserBadges ub ON rp.PostId = (SELECT AcceptedAnswerId FROM Posts WHERE Id = rp.PostId LIMIT 1)
    WHERE 
        rp.UserPostRank = 1 
        AND (rp.Score > 10 OR COALESCE(ub.BadgeCount, 0) > 0)
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.PostHistoryTypeId) AS HistoryTypeCount,
        STRING_AGG(DISTINCT CONCAT(pt.Name, ': ', ph.Comment), '; ') AS EditComments
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    hp.PostId,
    hp.Title,
    hp.CommentCount,
    hp.Score,
    COALESCE(pa.HistoryTypeCount, 0) AS HistoryTypeCount,
    pa.EditComments
FROM 
    HighScoringPosts hp
LEFT JOIN 
    PostHistoryAggregates pa ON hp.PostId = pa.PostId
WHERE 
    EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = hp.PostId 
        AND v.VoteTypeId IN (2, 3)  
        GROUP BY v.PostId
        HAVING COUNT(v.Id) > 5
    )
ORDER BY 
    hp.Score DESC,
    hp.CommentCount DESC
LIMIT 100 OFFSET 0;
