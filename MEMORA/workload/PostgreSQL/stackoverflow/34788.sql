WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
AnswersCount AS (
    SELECT 
        ParentId AS QuestionId,
        COUNT(*) AS AnswerCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 2 
    GROUP BY 
        ParentId
),
ClosedQuestionInfo AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostInsights AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(ac.AnswerCount, 0) AS AnswerCount,
        COALESCE(cqi.ClosedDate, NULL) AS ClosedDate,
        COALESCE(cqi.CloseReason, 'Open') AS CloseReason,
        ub.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        AnswersCount ac ON rp.PostId = ac.QuestionId
    LEFT JOIN 
        ClosedQuestionInfo cqi ON rp.PostId = cqi.PostId
    LEFT JOIN 
        UsersWithBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.UserPostRank = 1 
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.Score,
    pi.AnswerCount,
    pi.ClosedDate,
    pi.CloseReason,
    pi.BadgeCount,
    CASE 
        WHEN pi.BadgeCount > 5 THEN 'Highly Recognized' 
        ELSE 'Regular User' 
    END AS UserRecognition
FROM 
    PostInsights pi
WHERE 
    pi.Score > 10 
ORDER BY 
    pi.CreationDate DESC;