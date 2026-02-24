WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(COALESCE(vsd.VoteScore, 0)) AS AverageScore,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) - 
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS VoteScore
        FROM Votes
        GROUP BY PostId
    ) vsd ON vsd.PostId = p.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id
),

PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
        COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
        COALESCE(ch.CreationDate, p.LastActivityDate) AS LastActive
    FROM Posts p
    LEFT JOIN UserVoteStats vs ON vs.PostCount > 5 AND vs.UpVotes > vs.DownVotes
    LEFT JOIN (
        SELECT 
            PostId,
            MAX(CreationDate) AS CreationDate
        FROM Comments
        GROUP BY PostId
    ) ch ON ch.PostId = p.Id
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),

RankedPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.TotalUpVotes,
        pa.TotalDownVotes,
        pa.LastActive,
        RANK() OVER (ORDER BY pa.TotalUpVotes DESC, pa.TotalDownVotes ASC NULLS LAST) AS VoteRanking
    FROM PostActivity pa
),

FinalReport AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        COUNT(DISTINCT rp.PostId) AS ActivePosts,
        SUM(rp.TotalUpVotes) AS TotalUpVotes,
        SUM(rp.TotalDownVotes) AS TotalDownVotes,
        SUM(CASE WHEN rp.VoteRanking <= 10 THEN 1 ELSE 0 END) AS TopRankedPosts
    FROM UserVoteStats u
    JOIN RankedPosts rp ON u.UserId = rp.TotalUpVotes
    GROUP BY u.UserId, u.DisplayName
)

SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.ActivePosts,
    fr.TotalUpVotes,
    fr.TotalDownVotes,
    fr.TopRankedPosts,
    CASE 
        WHEN fr.TotalUpVotes > fr.TotalDownVotes THEN 'Positive Influence'
        WHEN fr.TotalUpVotes < fr.TotalDownVotes THEN 'Negative Influence'
        ELSE 'Neutral'
    END AS InfluenceType
FROM FinalReport fr
WHERE fr.ActivePosts > 5
ORDER BY fr.TotalUpVotes DESC, fr.TotalDownVotes ASC;