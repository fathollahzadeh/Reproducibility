WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Score,
        u.DisplayName AS OwnerName,
        COALESCE((
            SELECT 
                COUNT(*)
            FROM 
                Comments c
            WHERE 
                c.PostId = p.Id
        ), 0) AS CommentCount,
        COALESCE((
            SELECT 
                SUM(v.BountyAmount) 
            FROM 
                Votes v 
            WHERE 
                v.PostId = p.Id 
                AND v.VoteTypeId IN (8, 9)  
        ), 0) AS TotalBounty
    FROM 
        Posts p 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostVotes AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,  
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes  
    FROM 
        Votes
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.CommentCount,
        pv.UpVotes,
        pv.DownVotes,
        CASE 
            WHEN pv.UpVotes = 0 AND pv.DownVotes = 0 THEN 'No votes'
            WHEN pv.UpVotes > pv.DownVotes THEN 'Popular'
            ELSE 'Less popular'
        END AS Popularity,
        (rp.Score + COALESCE(rp.TotalBounty, 0)) AS TotalScore
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
),
RankedPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        TopPosts
)

SELECT 
    p.PostId,
    p.Title,
    p.OwnerName,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    p.Popularity,
    p.Rank,
    CASE 
        WHEN p.Rank <= 5 THEN 'Top 5 Posts'
        WHEN p.Rank <= 10 THEN 'Top 10 Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    RankedPosts p
WHERE 
    p.Popularity = 'Popular' OR p.CommentCount > 5
ORDER BY 
    p.Rank ASC;