WITH RecursivePostHistory AS (
    
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevNum
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        p.PostTypeId IN (1, 2)  
),
QuestionStats AS (
    
    SELECT 
        p.Id AS QuestionId,
        COUNT(a.Id) AS AnswerCount,
        MAX(p.Score) AS MaxScore,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId  
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id
),
UserBadgeCounts AS (
    
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    qs.QuestionId,
    qs.AnswerCount,
    qs.MaxScore,
    qs.AvgViewCount,
    qs.TotalUpVotes,
    qs.TotalDownVotes,
    ubc.BadgeCount,
    COALESCE(RPH.UserId, -1) AS LastEditorId,
    COALESCE(RPH.CreationDate, '1970-01-01') AS LastEditDate  
FROM 
    QuestionStats qs
LEFT JOIN 
    UserBadgeCounts ubc ON qs.QuestionId = ubc.UserId
LEFT JOIN 
    (SELECT DISTINCT ON (PostId)
        PostId,
        UserId,
        CreationDate
     FROM 
        RecursivePostHistory
     WHERE 
        RevNum = 1  
     ORDER BY 
        PostId, CreationDate DESC) AS RPH ON qs.QuestionId = RPH.PostId
WHERE 
    qs.AvgViewCount IS NOT NULL  
ORDER BY 
    qs.MaxScore DESC, 
    qs.AnswerCount DESC;