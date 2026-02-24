
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)
),
RecentUserVotes AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        u.Id
),
TopCommentedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
    HAVING 
        COUNT(*) > 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    COALESCE(tcp.TotalComments, 0) AS TotalComments,
    ru.UpVoteCount,
    ru.DownVoteCount,
    CASE 
        WHEN rp.ScoreRank = 1 THEN 'Top'
        WHEN rp.ScoreRank <= 5 THEN 'High'
        ELSE 'Misc'
    END AS RankCategory,
    CASE 
        WHEN rp.Score IS NULL THEN 'Score is NULL'
        ELSE 
            CASE 
                WHEN rp.Score < 0 THEN 'Negative Score'
                ELSE 'Positive Score'
            END
    END AS ScoreStatus,
    STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
FROM 
    RankedPosts rp
LEFT JOIN 
    TopCommentedPosts tcp ON rp.PostId = tcp.PostId
LEFT JOIN 
    Badges b ON b.UserId = rp.PostId
LEFT JOIN 
    RecentUserVotes ru ON ru.UserId = rp.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.CommentCount, tcp.TotalComments, ru.UpVoteCount, ru.DownVoteCount, rp.ScoreRank
ORDER BY 
    rp.Score DESC NULLS LAST, 
    rp.CreationDate DESC;
