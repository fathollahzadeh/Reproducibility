
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AcceptedAnswerId,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(AVG(p.Score), 0) AS AverageScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AcceptedAnswerId
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
RankingPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.ViewCount,
        pa.CommentCount,
        pa.AverageScore,
        DENSE_RANK() OVER (ORDER BY pa.ViewCount DESC, pa.AverageScore DESC) AS Rank
    FROM 
        PostActivity pa
    WHERE 
        pa.CommentCount > 5
)

SELECT 
    u.DisplayName AS UserName,
    u.UpVotesCount,
    u.DownVotesCount,
    u.TotalVotes,
    r.Title,
    r.ViewCount,
    r.CommentCount,
    r.AverageScore,
    r.Rank AS PostRank,
    CASE 
        WHEN r.ViewCount > 1000 THEN 'Highly Viewed'
        WHEN r.ViewCount BETWEEN 500 AND 1000 THEN 'Moderately Viewed'
        ELSE 'Low Views'
    END AS ViewCategory,
    CASE 
        WHEN php.PostHistoryTypeId IS NOT NULL THEN 'Edited/Closed'
        ELSE 'No Recent Edits'
    END AS PostStatus
FROM 
    UserVoteStats u
INNER JOIN 
    RankingPosts r ON u.UserId = r.PostId
LEFT JOIN 
    RecentPostHistory php ON r.PostId = php.PostId AND php.rn = 1
WHERE 
    (u.UpVotesCount - u.DownVotesCount) > 10
ORDER BY 
    r.Rank, u.DisplayName;
