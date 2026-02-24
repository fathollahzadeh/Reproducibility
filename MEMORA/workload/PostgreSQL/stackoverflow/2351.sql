WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
PostDetails AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.CreationDate, 
        rp.ViewCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
AggregatedData AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.CommentCount,
        pd.UpVoteCount,
        pd.DownVoteCount,
        u.Reputation,
        ub.BadgeCount,
        CASE 
            WHEN pd.ViewCount >= 1000 THEN 'High'
            WHEN pd.ViewCount >= 100 THEN 'Medium'
            ELSE 'Low' 
        END AS ViewLevel
    FROM 
        PostDetails pd
    JOIN 
        Users u ON pd.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
), 
FinalOutput AS (
    SELECT 
        *,
        (Score + UpVoteCount * 2 - DownVoteCount) AS EngagementScore
    FROM 
        AggregatedData
)
SELECT 
    Title,
    Score,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    Reputation,
    BadgeCount,
    ViewLevel,
    EngagementScore
FROM 
    FinalOutput
WHERE 
    EngagementScore > 10
ORDER BY 
    EngagementScore DESC
LIMIT 20;