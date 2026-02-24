
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN p.Id END) AS AcceptedQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation >= 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
QuestionHistory AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentEdit
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id 
    WHERE 
        p.PostTypeId = 1 AND ph.PostHistoryTypeId IN (4, 5, 6) 
),
ClosedQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        COUNT(ph.Id) AS ClosureCount
    FROM 
        Posts p 
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id
),
FinalReport AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.Upvotes,
        us.Downvotes,
        us.TotalPosts,
        us.AcceptedQuestions,
        qh.RecentEdit,
        cq.ClosureCount,
        CASE 
            WHEN cq.ClosureCount IS NULL THEN 'No Closures'
            WHEN cq.ClosureCount > 0 THEN 'Closed Multiple Times'
            ELSE 'Open'
        END AS QuestionStatus
    FROM 
        UserStats us
    LEFT JOIN 
        QuestionHistory qh ON us.UserId = qh.UserId AND qh.RecentEdit = 1
    LEFT JOIN 
        ClosedQuestions cq ON qh.PostId = cq.QuestionId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    Upvotes,
    Downvotes,
    TotalPosts,
    AcceptedQuestions,
    RecentEdit,
    QuestionStatus
FROM 
    FinalReport
WHERE 
    (Upvotes - Downvotes) > 10 
ORDER BY 
    Reputation DESC, AcceptedQuestions DESC
FETCH FIRST 10 ROWS ONLY;
