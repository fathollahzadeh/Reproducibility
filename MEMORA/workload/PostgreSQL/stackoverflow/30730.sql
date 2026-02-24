WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseCommentRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(mau.PostCount, 0) AS TotalPosts,
    COALESCE(mau.QuestionCount, 0) AS TotalQuestions,
    COALESCE(mau.AnswerCount, 0) AS TotalAnswers,
    COALESCE(ub.BadgeNames, 'No Gold Badges') AS GoldBadges,
    ph.PostId AS TopClosedQuestionId,
    ph.CreationDate AS ClosedDate,
    ph.Comment AS CloseReason,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = u.Id AND v.VoteTypeId = 2) AS UpVotes
FROM 
    Users u
LEFT JOIN 
    MostActiveUsers mau ON u.Id = mau.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    ClosedQuestions ph ON ph.PostId = (
        SELECT 
            PostId 
        FROM 
            ClosedQuestions 
        WHERE 
            CloseCommentRank = 1 
        ORDER BY 
            CreationDate DESC 
        LIMIT 1
    )
ORDER BY 
    TotalPosts DESC
LIMIT 10;