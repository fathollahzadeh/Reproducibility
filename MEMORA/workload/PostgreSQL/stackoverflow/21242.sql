WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - interval '1 year'
        AND p.Score > (SELECT AVG(Score) FROM Posts WHERE CreationDate >= cast('2024-10-01' as date) - interval '1 year') 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),

TopPosts AS (
    SELECT 
        PostId, Title, Score, CreationDate, OwnerUserId, CommentCount, UpVotes, DownVotes
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
),

UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

FinalStatistics AS (
    SELECT 
        p.Title,
        p.Score,
        p.CommentCount,
        p.UpVotes,
        p.DownVotes,
        u.DisplayName,
        COALESCE(u.GoldBadges, 0) AS GoldBadges,
        COALESCE(u.SilverBadges, 0) AS SilverBadges,
        COALESCE(u.BronzeBadges, 0) AS BronzeBadges
    FROM 
        TopPosts p
    JOIN 
        UserStatistics u ON p.OwnerUserId = u.UserId
)

SELECT 
    Title,
    Score,
    CommentCount,
    UpVotes,
    DownVotes,
    DisplayName,
    GoldBadges, 
    SilverBadges, 
    BronzeBadges,
    CASE 
        WHEN Score IS NULL THEN 'No Score'
        WHEN CommentCount = 0 THEN 'No Comments'
        ELSE 'Engagement Present'
    END AS EngagementLevel
FROM 
    FinalStatistics
ORDER BY 
    Score DESC, UpVotes DESC;