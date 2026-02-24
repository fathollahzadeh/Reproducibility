WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
        MAX(COALESCE(p.LastActivityDate, p.CreationDate)) AS MostRecentActivity
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS QuestionId,
        a.Id AS AcceptedAnswerId,
        a.OwnerUserId AS AnswerOwnerId
    FROM 
        Posts p
    JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1
),
UserPostDetails AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ps.PostId,
        ps.Upvotes,
        ps.Downvotes,
        COALESCE(aa.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        ps.CommentCount,
        ps.RelatedPostCount,
        CASE 
            WHEN ps.Upvotes > ps.Downvotes THEN 'Positive'
            WHEN ps.Upvotes < ps.Downvotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM 
        PostStatistics ps
    JOIN 
        UserReputation ur ON ps.OwnerUserId = ur.UserId
    LEFT JOIN 
        AcceptedAnswers aa ON ps.PostId = aa.QuestionId
)
SELECT 
    ud.DisplayName,
    ud.PostId,
    ud.Upvotes,
    ud.Downvotes,
    ud.AcceptedAnswerId,
    ud.CommentCount,
    ud.RelatedPostCount,
    ud.VoteSentiment,
    COALESCE(u.ReputationRank, 0) AS UserReputationRank
FROM 
    UserPostDetails ud
LEFT JOIN 
    UserReputation u ON ud.UserId = u.UserId
WHERE 
    ud.VoteSentiment = 'Positive' 
    AND (ud.CommentCount > 5 OR ud.RelatedPostCount > 2)
ORDER BY 
    u.ReputationRank, ud.Upvotes DESC;
