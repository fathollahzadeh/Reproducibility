WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
PostVoteSummary AS (
    SELECT 
        p.Id,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
CommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    tp.Id,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerName,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.TotalBounty,
    COALESCE(cs.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN pvs.UpVotes > pvs.DownVotes THEN 'Positive'
        WHEN pvs.UpVotes < pvs.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteSummary pvs ON tp.Id = pvs.Id
LEFT JOIN 
    CommentStats cs ON tp.Id = cs.PostId
ORDER BY 
    tp.Score DESC;