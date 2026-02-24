
WITH Rankings AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Creator,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT v.Id) DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.ViewCount
), RankedPosts AS (
    SELECT 
        PostId,
        Title,
        Creator,
        CommentCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        ViewCount,
        Rank
    FROM 
        Rankings
    WHERE 
        Rank <= 10
)
SELECT 
    rp.*,
    (UpVotes - DownVotes) AS NetVotes,
    CASE 
        WHEN AnswerCount >= 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS PopularityStatus
FROM 
    RankedPosts rp
ORDER BY 
    Rank;
