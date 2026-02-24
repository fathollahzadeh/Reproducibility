
WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.CreationDate AS HistoryCreationDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
),
ActiveUserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
TopQuestionsWithAnswerInfo AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.AcceptedAnswerId,
        COALESCE(a.Score, 0) AS AcceptedAnswerScore,
        COALESCE(a.ViewCount, 0) AS AcceptedAnswerViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1
),
RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        MAX(c.CreationDate) AS LastCommentDate,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    p.Id AS PostId,
    p.Title,
    CASE 
        WHEN a.UserId IS NOT NULL THEN 'Badge Holder'
        ELSE 'Regular User'
    END AS UserType,
    COALESCE(q.AcceptedAnswerScore, 0) AS AcceptedAnswerScore,
    COALESCE(q.AcceptedAnswerViewCount, 0) AS AcceptedAnswerViewCount,
    ph.HistoryCreationDate,
    a.BadgeCount,
    ra.CommentCount,
    ra.LastCommentDate
FROM 
    Posts p
LEFT JOIN 
    ActiveUserBadgeCounts a ON p.OwnerUserId = a.UserId
LEFT JOIN 
    TopQuestionsWithAnswerInfo q ON p.Id = q.QuestionId
LEFT JOIN 
    RecursivePostHistory ph ON p.Id = ph.PostId AND ph.rn = 1
LEFT JOIN 
    RecentPostActivity ra ON p.Id = ra.PostId
WHERE 
    p.PostTypeId = 1 
    AND p.ViewCount > 100
ORDER BY 
    ra.CommentCount DESC, 
    q.AcceptedAnswerScore DESC, 
    p.CreationDate DESC
LIMIT 100;
