
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.PostTypeId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT bl.PostId) AS RelatedPostCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks bl ON p.Id = bl.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId
), 
PostRanking AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        rp.RelatedPostCount,
        RANK() OVER (
            ORDER BY (rp.UpVotes - rp.DownVotes) DESC, 
                     rp.CommentCount DESC
        ) AS Rank
    FROM 
        RecentPosts rp
)
SELECT 
    pr.PostId, 
    pr.Title, 
    pr.UpVotes, 
    pr.DownVotes, 
    pr.CommentCount,
    pr.RelatedPostCount,
    CASE 
        WHEN pr.Rank IS NULL THEN 'Unranked' 
        ELSE CAST(pr.Rank AS VARCHAR)
    END AS PostRankStatus,
    COALESCE(
        (SELECT 
            COUNT(b.Id) 
         FROM 
            Badges b 
         WHERE 
            b.UserId = p.OwnerUserId AND 
            b.Class = 1), 0
    ) AS GoldBadgesCount
FROM 
    PostRanking pr
LEFT JOIN 
    Posts p ON pr.PostId = p.Id
WHERE 
    p.OwnerUserId IS NOT NULL
ORDER BY 
    pr.Rank, 
    pr.UpVotes DESC NULLS LAST
FETCH NEXT 100 ROWS ONLY;
