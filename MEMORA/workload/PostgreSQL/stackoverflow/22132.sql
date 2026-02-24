
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.UserPostRank,
        rp.CommentCount,
        COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS ScoreDifference
    FROM 
        RankedPosts rp
        LEFT JOIN (
            SELECT 
                PostId,
                SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
            FROM 
                Votes
            GROUP BY 
                PostId
        ) v ON rp.PostId = v.PostId
    WHERE 
        rp.UserPostRank = 1  
        AND (v.UpVotes IS NULL OR v.UpVotes > 5 OR v.DownVotes IS NULL OR v.DownVotes = 0)  
),
ClosedPostHistory AS (
    SELECT 
        PostId,
        COUNT(Ph.Id) AS CloseCount
    FROM 
        PostHistory Ph
    WHERE 
        Ph.PostHistoryTypeId = 10  
    GROUP BY 
        PostId
),
FinalSelection AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.OwnerDisplayName,
        fp.ScoreDifference,
        cp.CloseCount
    FROM 
        FilteredPosts fp
        LEFT JOIN ClosedPostHistory cp ON fp.PostId = cp.PostId
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.CreationDate,
    fs.OwnerDisplayName,
    fs.ScoreDifference,
    COALESCE(fs.CloseCount, 0) AS CloseCount,
    CASE 
        WHEN fs.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CONCAT('User: ', fs.OwnerDisplayName, ' asked: ', fs.Title) AS FullDescription,
    ARRAY_AGG(DISTINCT t.TagName) AS TagsUsed
FROM 
    FinalSelection fs
    LEFT JOIN LATERAL (
        SELECT 
            unnest(string_to_array(p.Tags, ',')) AS TagName
        FROM 
            Posts p
        WHERE 
            p.Id = fs.PostId
    ) t ON TRUE
GROUP BY 
    fs.PostId, fs.Title, fs.CreationDate, fs.OwnerDisplayName, fs.ScoreDifference, fs.CloseCount
HAVING 
    COALESCE(fs.CloseCount, 0) < 3  
ORDER BY 
    fs.ScoreDifference DESC,
    fs.CreationDate DESC;
