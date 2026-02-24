WITH UserVoteSummary AS (
    SELECT
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON v.PostId = p.Id
    GROUP BY u.Id
),
PostAcceptance AS (
    SELECT
        p.Id AS PostId,
        COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN p.AcceptedAnswerId END) AS AcceptedAnswers
    FROM Posts p
    GROUP BY p.Id
),
PostDetails AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(ps.TotalUpVotes, 0) AS UserUpVotes,
        COALESCE(ps.TotalDownVotes, 0) AS UserDownVotes,
        COALESCE(pa.AcceptedAnswers, 0) AS AcceptedAnswersCount
    FROM Posts p
    LEFT JOIN UserVoteSummary ps ON p.OwnerUserId = ps.UserId
    LEFT JOIN PostAcceptance pa ON p.Id = pa.PostId
)
SELECT
    pd.Id,
    pd.Title,
    pd.CreationDate,
    pd.UserUpVotes,
    pd.UserDownVotes,
    pd.AcceptedAnswersCount,
    CASE 
        WHEN pd.UserUpVotes > pd.UserDownVotes THEN 'Positive' 
        WHEN pd.UserDownVotes > pd.UserUpVotes THEN 'Negative' 
        ELSE 'Neutral' 
    END AS VoteSentiment,
    CASE 
        WHEN pd.AcceptedAnswersCount > 0 THEN 'Accepted' 
        ELSE 'Not Accepted' 
    END AS AcceptanceStatus
FROM PostDetails pd
WHERE pd.CreationDate >= '2021-01-01'
  AND (pd.UserUpVotes - pd.UserDownVotes) > 0
ORDER BY pd.UserUpVotes DESC, pd.CreationDate DESC
LIMIT 100;
