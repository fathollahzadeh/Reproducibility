
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, pt.Name
),
PostRankings AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.ViewCount, 
        rp.Score, 
        rp.RankByScore, 
        rp.UpVotes, 
        rp.DownVotes, 
        rp.GoldBadges, 
        rp.SilverBadges, 
        rp.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS OverallRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 10
)
SELECT 
    pr.PostId, 
    pr.Title, 
    pr.ViewCount, 
    pr.Score, 
    pr.UpVotes, 
    pr.DownVotes, 
    pr.GoldBadges, 
    pr.SilverBadges, 
    pr.BronzeBadges, 
    pr.OverallRank
FROM 
    PostRankings pr
WHERE 
    pr.OverallRank <= 50
ORDER BY 
    pr.OverallRank;
