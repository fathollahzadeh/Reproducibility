WITH UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes v
    GROUP BY v.UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS TotalUpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS TotalDownVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId IN (6, 10) THEN v.Id END) AS TotalCloseVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.OwnerUserId
),
FinalStats AS (
    SELECT 
        pst.PostId,
        pst.OwnerUserId,
        pst.TotalCommentScore,
        pst.TotalComments,
        pst.TotalUpVotes,
        pst.TotalDownVotes,
        COALESCE(ABS(pst.TotalUpVotes - pst.TotalDownVotes), 0) AS VoteDifference,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Anonymous'
            ELSE u.DisplayName
        END AS UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pst.OwnerUserId ORDER BY pst.TotalCommentScore DESC) AS UserRank
    FROM PostStats pst
    LEFT JOIN Users u ON pst.OwnerUserId = u.Id
)
SELECT 
    fs.PostId,
    fs.UserDisplayName,
    fs.TotalCommentScore,
    fs.TotalComments,
    fs.TotalUpVotes,
    fs.TotalDownVotes,
    fs.VoteDifference,
    fs.UserRank,
    CASE 
        WHEN fs.TotalComments > 5 THEN 'Popular'
        WHEN fs.TotalComments >= 1 AND fs.TotalComments <= 5 THEN 'Moderate Activity'
        ELSE 'No Comments'
    END AS ActivityLevel
FROM FinalStats fs
WHERE fs.VoteDifference > 10
ORDER BY fs.TotalCommentScore DESC;
