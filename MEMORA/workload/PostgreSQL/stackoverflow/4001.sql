WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalQuestions,
        COUNT(a.Id) AS TotalAnswers,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM 
        Posts p 
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.UserId) AS CloseVoteCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
FinalOutput AS (
    SELECT 
        ur.UserId,
        ur.TotalQuestions,
        ur.TotalAnswers,
        ur.Reputation,
        ur.ReputationLevel,
        cp.CloseVoteCount,
        COALESCE(rp.Title, 'No Questions') AS LatestQuestionTitle
    FROM 
        UserReputation ur
    LEFT JOIN 
        ClosedPosts cp ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
    LEFT JOIN 
        RankedPosts rp ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.Id)
)
SELECT 
    *
FROM 
    FinalOutput
WHERE 
    TotalQuestions > 0 OR CloseVoteCount IS NOT NULL
ORDER BY 
    TotalQuestions DESC, CloseVoteCount DESC;