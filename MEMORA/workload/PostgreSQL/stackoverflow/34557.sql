
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN ph.CreationDate > p.CreationDate AND ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedQuestions
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 ELSE NULL END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 ELSE NULL END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 ELSE NULL END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserActivity AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        tu.QuestionCount,
        tu.ClosedQuestions,
        COUNT(cp.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        TopUsers tu ON u.Id = tu.UserId
    LEFT JOIN 
        Comments cp ON u.Id = cp.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, tu.QuestionCount, tu.ClosedQuestions, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
)
SELECT 
    ua.DisplayName,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ua.QuestionCount,
    ua.ClosedQuestions,
    MAX(rp.Title) AS TopQuestionTitle,
    MAX(rp.Score) AS TopQuestionScore,
    MAX(rp.ViewCount) AS TopQuestionViews,
    ua.UpVotes,
    ua.CommentCount
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts rp ON ua.Id = rp.OwnerUserId AND rp.Rank = 1
GROUP BY 
    ua.DisplayName, ua.GoldBadges, ua.SilverBadges, ua.BronzeBadges, ua.QuestionCount, ua.ClosedQuestions, ua.UpVotes, ua.CommentCount
ORDER BY 
    ua.QuestionCount DESC, ua.ClosedQuestions ASC, ua.UpVotes DESC;
