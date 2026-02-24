
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostsCount,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - u.CreationDate)) / 3600) AS AvgHoursOnline
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
QuestionStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveScoredQuestions,
        COALESCE(MAX(p.CreationDate), DATE '1970-01-01') AS LastQuestionDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.OwnerUserId
),
UserEngagement AS (
    SELECT 
        us.DisplayName,
        us.Reputation,
        us.UpVotes,
        us.DownVotes,
        qs.QuestionsAsked,
        qs.PositiveScoredQuestions,
        qs.LastQuestionDate,
        RANK() OVER (ORDER BY us.Reputation DESC) AS ReputationRank,
        us.UserId
    FROM 
        UserStatistics us
    LEFT JOIN 
        QuestionStatistics qs ON us.UserId = qs.OwnerUserId
)
SELECT 
    ue.DisplayName,
    ue.Reputation,
    ue.ReputationRank,
    nd.CreationDate AS NewestVoteDate,
    nd.NewestVoteType,
    COALESCE(ue.QuestionsAsked, 0) AS QuestionsAsked,
    COALESCE(ue.PositiveScoredQuestions, 0) AS PositiveScoredQuestions,
    CASE 
        WHEN ue.QuestionsAsked > 0 AND ue.PositiveScoredQuestions = 0 THEN 'Needs Improvement'
        WHEN ue.PositiveScoredQuestions > 0 THEN 'Contributing'
        ELSE 'Passive User'
    END AS UserCategory,
    pn.CommentsCount AS PostNoticeCommentsCount
FROM 
    UserEngagement ue
LEFT JOIN (
    SELECT 
        u.Id AS UserId,
        MAX(v.CreationDate) AS CreationDate,
        CASE 
            WHEN SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 
                 SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) 
            THEN 'Positive' 
            ELSE 'Negative' 
        END AS NewestVoteType
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
) nd ON ue.UserId = nd.UserId
LEFT JOIN (
    SELECT 
        post.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentsCount
    FROM 
        Posts post
    LEFT JOIN 
        Comments c ON post.Id = c.PostId
    GROUP BY 
        post.OwnerUserId
) pn ON ue.UserId = pn.OwnerUserId
WHERE 
    ue.ReputationRank <= 10  
ORDER BY 
    ue.Reputation DESC, ue.ReputationRank;
