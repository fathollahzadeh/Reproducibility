WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        BadgeCount,
        GoldCount,
        SilverCount,
        BronzeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserBadgeCounts ub
    JOIN 
        Users u ON ub.UserId = u.Id
),
PostStatistics AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CommentCount) AS TotalComments,
        SUM(ViewCount) AS TotalViews,
        RANK() OVER (ORDER BY SUM(ViewCount) DESC) AS ViewRank
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
CombinedStats AS (
    SELECT 
        tu.UserId,
        tu.Reputation,
        tu.BadgeCount,
        tu.GoldCount,
        tu.SilverCount,
        tu.BronzeCount,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalComments, 0) AS TotalComments,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        tu.ReputationRank,
        ps.ViewRank
    FROM 
        TopUsers tu
    LEFT JOIN 
        PostStatistics ps ON tu.UserId = ps.OwnerUserId
)
SELECT 
    c.UserId,
    c.Reputation,
    c.BadgeCount,
    c.GoldCount,
    c.SilverCount,
    c.BronzeCount,
    c.PostCount,
    c.QuestionCount,
    c.AnswerCount,
    c.TotalComments,
    c.TotalViews,
    c.ReputationRank,
    c.ViewRank
FROM 
    CombinedStats c
WHERE 
    c.ReputationRank <= 10 OR c.ViewRank <= 10
ORDER BY 
    c.ReputationRank, c.ViewRank;
