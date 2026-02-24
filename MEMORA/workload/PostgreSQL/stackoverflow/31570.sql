WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
RecentQuestions AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate,
        ViewCount
    FROM 
        RecursiveCTE
    WHERE 
        rn <= 10 
),
AnsweredQuestions AS (
    SELECT 
        rq.PostId,
        rq.Title,
        rq.CreationDate,
        rq.ViewCount,
        COUNT(a.Id) AS AnswerCount
    FROM 
        RecentQuestions rq
    LEFT JOIN 
        Posts a ON rq.PostId = a.ParentId 
    GROUP BY 
        rq.PostId, rq.Title, rq.CreationDate, rq.ViewCount
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
FinalResults AS (
    SELECT 
        aq.PostId,
        aq.Title,
        aq.CreationDate,
        aq.ViewCount,
        aq.AnswerCount,
        ub.DisplayName,
        ub.BadgeCount
    FROM 
        AnsweredQuestions aq
    JOIN 
        RecentQuestions rq ON aq.PostId = rq.PostId
    JOIN 
        Users u ON rq.PostId = u.Id 
    LEFT JOIN 
        UserWithBadges ub ON u.Id = ub.UserId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    fr.AnswerCount,
    fr.DisplayName,
    COALESCE(fr.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN fr.AnswerCount > 0 THEN 'Answered'
        ELSE 'Not Answered'
    END AS AnswerStatus
FROM 
    FinalResults fr
WHERE 
    fr.ViewCount > 100 
ORDER BY 
    fr.CreationDate DESC;