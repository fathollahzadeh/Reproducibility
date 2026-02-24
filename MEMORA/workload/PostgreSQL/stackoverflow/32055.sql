
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views, u.UpVotes, u.DownVotes
),
CommentStatistics AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostViewCounts AS (
    SELECT 
        p.Id AS PostId,
        p.ViewCount,
        COALESCE(cs.CommentCount, 0) AS TotalComments,
        p.Score AS PostScore,
        CASE 
            WHEN p.Score >= 100 THEN 'High'
            WHEN p.Score BETWEEN 50 AND 99 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        Posts p
    LEFT JOIN 
        CommentStatistics cs ON p.Id = cs.PostId
    WHERE 
        p.PostTypeId = 1 
),
FinalResults AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.Reputation,
        ups.Views,
        ups.GoldBadges,
        ups.SilverBadges,
        ups.BronzeBadges,
        pvc.PostId,
        pvc.ViewCount,
        pvc.TotalComments,
        pvc.PostScore,
        pvc.ScoreCategory,
        rp.Title AS TopScoringPostTitle
    FROM 
        UserStatistics ups
    LEFT JOIN 
        PostViewCounts pvc ON ups.UserId = pvc.PostId
    LEFT JOIN 
        RankedPosts rp ON ups.UserId = rp.OwnerUserId AND rp.ScoreRank = 1
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    Views,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    COUNT(PostId) AS TotalPosts,
    SUM(ViewCount) AS TotalViews,
    SUM(TotalComments) AS TotalComments,
    AVG(PostScore) AS AveragePostScore,
    STRING_AGG(DISTINCT ScoreCategory, ', ') AS ScoreCategories
FROM 
    FinalResults
GROUP BY 
    UserId, DisplayName, Reputation, Views, GoldBadges, SilverBadges, BronzeBadges
ORDER BY 
    Reputation DESC, TotalViews DESC;
