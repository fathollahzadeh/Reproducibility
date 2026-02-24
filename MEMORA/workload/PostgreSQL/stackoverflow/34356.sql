WITH RECURSIVE UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (1, 8) THEN 1 ELSE 0 END) AS AcceptedVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1
    AND p.Score > 0
),
PostLinksAggregated AS (
    SELECT 
        p.Id AS PostId,
        COUNT(pl.RelatedPostId) AS LinkCount,
        STRING_AGG(DISTINCT lt.Name, ', ') AS LinkTypes
    FROM Posts p
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY p.Id
)
SELECT
    u.DisplayName,
    u.Reputation,
    ul.TotalVotes,
    ul.UpVotes,
    ul.DownVotes,
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.CreationDate,
    pla.LinkCount,
    pla.LinkTypes
FROM Users u
JOIN UserVoteCounts ul ON u.Id = ul.UserId
JOIN TopPosts pp ON pp.Rank <= 10
LEFT JOIN PostLinksAggregated pla ON pp.PostId = pla.PostId
WHERE 
    u.Reputation > 100
    AND (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 1) > 0  
ORDER BY ul.TotalVotes DESC, pp.ViewCount DESC
LIMIT 50;