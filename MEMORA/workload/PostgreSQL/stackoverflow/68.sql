WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId, u.DisplayName
),
PostAnalytics AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Author,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.rn,
        (rp.UpVotes - rp.DownVotes) AS Score,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Highly Engaged'
            WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Engaged'
            ELSE 'Minimally Engaged'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
)
SELECT 
    pa.Id,
    pa.Title,
    pa.CreationDate,
    pa.Author,
    pa.CommentCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.Score,
    pa.EngagementLevel,
    CASE 
        WHEN pa.Score > 5 THEN 'Popular'
        WHEN pa.Score BETWEEN 0 AND 5 THEN 'Average'
        ELSE 'Unpopular'
    END AS PopularityLevel
FROM 
    PostAnalytics pa
WHERE 
    pa.rn <= 10
ORDER BY 
    pa.Score DESC, pa.CreationDate DESC
LIMIT 50;