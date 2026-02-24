WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) as VersionRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)  
),
UserReputationTotales AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= '2021-01-01'  
    GROUP BY 
        u.Id
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
QuestionsWithAcceptedAnswers AS (
    SELECT 
        p.Id AS QuestionId,
        p.AcceptedAnswerId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(ans.OwnerUserId, -1) AS AcceptedAnswerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Posts ans ON p.AcceptedAnswerId = ans.Id
    WHERE 
        p.PostTypeId = 1  
)
SELECT 
    q.Title,
    q.CreationDate,
    q.Score,
    COALESCE(ph.VersionRank, 0) AS CloseOpenDeleteCount,
    u.TotalReputation,
    pov.UpVotes,
    pov.DownVotes,
    pov.TotalVotes,
    CASE 
        WHEN q.AcceptedAnswerUserId <> -1 THEN 'Has Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus,
    CASE 
        WHEN ph.VersionRank IS NULL THEN 'Not Closed/Open/Deleted'
        ELSE 'Closed/Open/Deleted'
    END AS PostHistoryStatus
FROM 
    QuestionsWithAcceptedAnswers q
LEFT JOIN 
    RecursivePostHistory ph ON q.QuestionId = ph.PostId
LEFT JOIN 
    UserReputationTotales u ON q.AcceptedAnswerUserId = u.UserId
LEFT JOIN 
    PostVoteCounts pov ON q.QuestionId = pov.PostId
WHERE 
    (ph.VersionRank IS NOT NULL OR q.AcceptedAnswerUserId IS NOT NULL)  
ORDER BY 
    q.Score DESC, 
    u.TotalReputation DESC
LIMIT 100;