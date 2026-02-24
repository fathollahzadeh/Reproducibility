
WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        ub.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users ub
    LEFT JOIN 
        Badges b ON ub.Id = b.UserId
    GROUP BY 
        ub.Id
),
TopUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.PostCount,
        u.AnswerCount,
        u.QuestionCount,
        u.AverageScore,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        UserPostStats u
    LEFT JOIN 
        UserBadges ub ON u.UserId = ub.UserId
    WHERE 
        u.PostCount > 10
    ORDER BY 
        u.AverageScore DESC, ub.BadgeCount DESC
    LIMIT 10
),
PostsWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    COALESCE(tu.BadgeCount, 0) AS BadgeCount,
    COALESCE(tu.BadgeNames, '') AS BadgeNames,
    tw.PostId,
    tw.Title,
    COALESCE(tw.VoteCount, 0) AS VoteCount,
    CASE 
        WHEN tw.VoteCount = 0 THEN 'No votes'
        ELSE 'Votes received: ' || tw.VoteCount
    END AS VoteSummary,
    CASE 
        WHEN tu.QuestionCount > 0 THEN 'Questions asked: ' || tu.QuestionCount
        ELSE 'No questions asked'
    END AS QuestionSummary
FROM 
    TopUsers tu
LEFT JOIN 
    PostsWithVotes tw ON tu.UserId = tw.OwnerUserId
ORDER BY 
    tu.AverageScore DESC, tu.BadgeCount DESC;
