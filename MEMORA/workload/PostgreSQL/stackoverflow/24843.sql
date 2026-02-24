WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerName,
        CommentCount,
        UpVotes,
        DownVotes,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostEngagements AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerName,
        COALESCE(tp.CommentCount, 0) AS TotalComments,
        COALESCE(tp.UpVotes, 0) - COALESCE(tp.DownVotes, 0) AS NetVotes,
        CASE 
            WHEN COALESCE(tp.UpVotes, 0) - COALESCE(tp.DownVotes, 0) > 0 
            THEN 'Positive Engagement'
            WHEN COALESCE(tp.UpVotes, 0) - COALESCE(tp.DownVotes, 0) = 0 
            THEN 'Neutral Engagement'
            ELSE 'Negative Engagement'
        END AS EngagementType
    FROM 
        TopPosts tp
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.OwnerName,
    pe.TotalComments,
    pe.NetVotes,
    pe.EngagementType,
    COUNT(b.Id) AS BadgeCount,
    STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
FROM 
    PostEngagements pe
LEFT JOIN 
    Badges b ON pe.OwnerName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
GROUP BY 
    pe.PostId, pe.Title, pe.OwnerName, pe.TotalComments, pe.NetVotes, pe.EngagementType
ORDER BY 
    pe.NetVotes DESC NULLS LAST, pe.TotalComments DESC NULLS LAST;