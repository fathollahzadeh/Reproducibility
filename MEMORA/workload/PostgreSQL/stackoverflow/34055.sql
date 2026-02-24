WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.Reputation, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
),
FinalResults AS (
    SELECT 
        ups.UserId,
        ups.Reputation,
        ups.GoldBadges,
        ups.SilverBadges,
        ups.BronzeBadges,
        ups.QuestionCount,
        ups.TotalViews,
        ups.TotalScore,
        r.PostRank,
        MAX(r.AnswerCount) AS MaxAnswerCount,
        MAX(r.UpvoteCount + r.DownvoteCount) AS TotalVotes
    FROM 
        UserStatistics ups
    LEFT JOIN 
        RankedPosts r ON ups.UserId = r.OwnerUserId
    GROUP BY 
        ups.UserId, ups.Reputation, ups.GoldBadges, ups.SilverBadges, ups.BronzeBadges, ups.QuestionCount, ups.TotalViews, ups.TotalScore, r.PostRank
)
SELECT 
    UserId,
    Reputation,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    QuestionCount,
    TotalViews,
    TotalScore,
    PostRank,
    MaxAnswerCount,
    TotalVotes
FROM 
    FinalResults
WHERE 
    QuestionCount > 10
ORDER BY 
    Reputation DESC, TotalVotes DESC;