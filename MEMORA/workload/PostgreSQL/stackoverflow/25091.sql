WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopRankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount
    FROM 
        RankedUsers
    WHERE 
        ReputationRank <= 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserRecentActivity AS (
    SELECT 
        c.UserDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS PostHistoryCount,
        MAX(c.CreationDate) AS LatestCommentDate
    FROM 
        Comments c
    LEFT JOIN 
        PostHistory ph ON c.PostId = ph.PostId
    GROUP BY 
        c.UserDisplayName
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    ub.BadgeNames,
    ura.CommentCount,
    ura.PostHistoryCount,
    ura.LatestCommentDate
FROM 
    TopRankedUsers u
LEFT JOIN 
    UserBadges ub ON u.UserId = ub.UserId
LEFT JOIN 
    UserRecentActivity ura ON u.DisplayName = ura.UserDisplayName
ORDER BY 
    u.Reputation DESC;
