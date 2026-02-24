
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER(PARTITION BY p.Id) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER(PARTITION BY p.Id) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.LastAccessDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '7 days'
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpvoteCount,
        rp.DownvoteCount,
        CASE 
            WHEN rp.UpvoteCount = 0 AND rp.DownvoteCount = 0 THEN 'No Votes'
            WHEN rp.UpvoteCount > rp.DownvoteCount THEN 'Positive Feedback'
            WHEN rp.UpvoteCount < rp.DownvoteCount THEN 'Negative Feedback'
            ELSE 'Mixed Feedback'
        END AS FeedbackType,
        au.UserId,
        au.DisplayName AS TopUser,
        au.BadgeCount,
        au.GoldBadges,
        au.SilverBadges,
        au.BronzeBadges
    FROM 
        RankedPosts rp
    FULL OUTER JOIN 
        ActiveUsers au ON rp.OwnerUserId = au.UserId
    WHERE 
        rp.ScoreRank <= 5 OR au.BadgeCount > 0
),
FinalStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.FeedbackType,
        COALESCE(ps.UpvoteCount, 0) - COALESCE(ps.DownvoteCount, 0) AS NetVotes,
        ps.TopUser,
        ps.BadgeCount,
        ROW_NUMBER() OVER(ORDER BY COALESCE(ps.UpvoteCount, 0) - COALESCE(ps.DownvoteCount, 0) DESC) AS PopularityRank
    FROM 
        PostStats ps
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.FeedbackType,
    fs.NetVotes,
    fs.TopUser,
    fs.BadgeCount,
    fs.PopularityRank,
    CASE 
        WHEN fs.NetVotes IS NULL THEN 'Unscored'
        WHEN fs.NetVotes > 0 THEN 'Winning Posts'
        ELSE 'Losing Posts'
    END AS PostStatus
FROM 
    FinalStats fs
WHERE 
    fs.PopularityRank <= 10
ORDER BY 
    fs.PopularityRank;
