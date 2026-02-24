
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostID,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        Tags,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        UserRank <= 3 
),
EngagedPosts AS (
    SELECT 
        tp.PostID,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostID = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostID = v.PostId
    GROUP BY 
        tp.PostID, tp.Title, tp.Score, tp.ViewCount
),
FinalReport AS (
    SELECT 
        ep.PostID,
        ep.Title,
        ep.Score,
        ep.ViewCount,
        ep.CommentCount,
        ep.TotalUpVotes,
        ep.TotalDownVotes,
        (ep.TotalUpVotes - ep.TotalDownVotes) AS NetVotes,
        CASE 
            WHEN ep.Score >= 100 THEN 'Highly Engaged'
            WHEN ep.Score >= 50 THEN 'Moderately Engaged'
            ELSE 'Low Engagement' 
        END AS EngagementLevel
    FROM 
        EngagedPosts ep
)
SELECT 
    f.PostID,
    f.Title,
    f.Score,
    f.ViewCount,
    f.CommentCount,
    f.TotalUpVotes,
    f.TotalDownVotes,
    f.NetVotes,
    f.EngagementLevel
FROM 
    FinalReport f
ORDER BY 
    f.NetVotes DESC, f.Score DESC
FETCH FIRST 20 ROWS ONLY;
