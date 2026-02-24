
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId, p.Title, p.CreationDate
),
UserPostStats AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        SUM(ap.UpVoteCount) AS TotalUpVotes,
        SUM(ap.DownVoteCount) AS TotalDownVotes,
        SUM(ap.CommentCount) AS TotalComments,
        SUM(CASE WHEN ap.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        UserReputation ur
    LEFT JOIN 
        ActivePosts ap ON ur.UserId = ap.OwnerUserId
    GROUP BY 
        ur.UserId, ur.DisplayName
), 
CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalUpVotes,
        ups.TotalDownVotes,
        ups.TotalComments,
        ups.QuestionCount,
        ur.Reputation,
        CASE 
            WHEN ups.TotalUpVotes > ups.TotalDownVotes THEN 'More UpVotes'
            ELSE 'More DownVotes'
        END AS VoteTrend
    FROM 
        UserPostStats ups
    JOIN 
        UserReputation ur ON ups.UserId = ur.UserId
)
SELECT 
    cs.DisplayName,
    cs.Reputation,
    cs.TotalUpVotes,
    cs.TotalDownVotes,
    cs.TotalComments,
    cs.QuestionCount,
    cs.VoteTrend,
    CASE 
        WHEN cs.Reputation IS NULL THEN 'No Reputation Found'
        ELSE 'Reputation Exists'
    END AS ReputationStatus
FROM 
    CombinedStats cs
WHERE 
    cs.QuestionCount > 0
    AND cs.Reputation IS NOT NULL
ORDER BY 
    cs.Reputation DESC,
    cs.DisplayName ASC;
