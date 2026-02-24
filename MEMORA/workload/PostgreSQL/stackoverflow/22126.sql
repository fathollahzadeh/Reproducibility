
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RankByType,
        COALESCE(p.AcceptedAnswerId, 0) AS HasAcceptedAnswer,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes  
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AcceptedAnswerId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        HasAcceptedAnswer,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        RankByType <= 5  
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
EnhancedPostInfo AS (
    SELECT 
        tp.*,
        u.DisplayName AS PostOwner,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        TopPosts tp
    JOIN 
        Users u ON tp.PostId = u.Id  
    LEFT JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
)

SELECT 
    epi.PostId,
    epi.Title,
    epi.CreationDate,
    epi.Score,
    epi.ViewCount,
    CASE 
        WHEN epi.HasAcceptedAnswer = 0 THEN 'No Accepted Answer'
        ELSE 'Has Accepted Answer'
    END AS AnswerStatus,
    epi.CommentCount,
    epi.UpVotes,
    epi.DownVotes,
    epi.PostOwner,
    COALESCE(epi.BadgeCount, 0) AS BadgeCount,
    COALESCE(epi.BadgeNames, 'None') AS BadgeNames,
    CONCAT('Post Score: ', epi.Score, ' with ', epi.ViewCount, ' views.') AS PostScoreDetail
FROM 
    EnhancedPostInfo epi
WHERE 
    epi.Score > (SELECT AVG(Score) FROM Posts)  
ORDER BY 
    epi.Score DESC, epi.ViewCount DESC
LIMIT 50;
