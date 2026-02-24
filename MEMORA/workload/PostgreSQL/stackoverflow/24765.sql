
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes 
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate, p.ViewCount
),
UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpVotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AvgDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    u.DisplayName AS TopVoter,
    SUM(CASE 
        WHEN uvs.TotalVotes > 5 THEN 1 
        ELSE 0 
    END) AS NotableVoterCount,
    (p.UpVotes - p.DownVotes) AS Score,
    CASE 
        WHEN p.Rank = 1 THEN 'Top' 
        WHEN p.Rank <= 5 THEN 'Top 5'
        ELSE 'Others' 
    END AS PostRankCategory
FROM 
    RankedPosts p
LEFT JOIN 
    UserVoteSummary uvs ON p.UpVotes = uvs.AvgUpVotes
LEFT JOIN 
    Users u ON u.Id = (SELECT v.UserId 
                        FROM Votes v 
                        WHERE v.PostId = p.PostId 
                        ORDER BY v.CreationDate DESC
                        LIMIT 1)
WHERE 
    p.Rank <= 10
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, p.UpVotes, p.DownVotes, p.Rank
ORDER BY 
    Score DESC, p.ViewCount DESC;
