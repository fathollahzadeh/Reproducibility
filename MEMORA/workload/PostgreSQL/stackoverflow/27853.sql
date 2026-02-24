WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Body,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(SUM(v.VoteTypeId), 0) DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Body,
        rp.OwnerName,
        rp.TotalComments,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Tags,
    fp.Body,
    fp.OwnerName,
    fp.TotalComments,
    fp.UpVotes,
    fp.DownVotes,
    CASE 
        WHEN fp.UpVotes - fp.DownVotes > 0 THEN 'Positive'
        WHEN fp.UpVotes - fp.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    FilteredPosts fp
ORDER BY 
    fp.TotalComments DESC, 
    fp.UpVotes - fp.DownVotes DESC;