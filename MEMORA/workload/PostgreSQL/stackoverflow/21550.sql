WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Rank,
        rp.CommentCount,
        rp.UpVotesCount,
        rp.DownVotesCount,
        CASE 
            WHEN rp.UpVotesCount > 0 AND rp.DownVotesCount > 0 
            THEN (CAST(rp.UpVotesCount AS FLOAT) / (rp.UpVotesCount + rp.DownVotesCount)) * 100 
            ELSE NULL 
        END AS UpsRatio
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
),
MouseOverDetails AS (
    SELECT 
        fp.Title AS PostTitle,
        'Score: ' || CAST(fp.Score AS VARCHAR) || ', Comments: ' || CAST(fp.CommentCount AS VARCHAR) AS TooltipDetails,
        CASE 
            WHEN fp.UpsRatio IS NULL THEN 'No votes yet' 
            ELSE 'Approval Rating: ' || CAST(fp.UpsRatio AS VARCHAR) || '%'
        END AS ApprovalStatus
    FROM 
        FilteredPosts fp
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ud.UserId,
    ud.BadgeNames,
    md.PostTitle,
    md.TooltipDetails,
    md.ApprovalStatus
FROM 
    UserBadges ud
JOIN 
    MouseOverDetails md ON ud.UserId = (SELECT OwnerUserId FROM Posts p WHERE p.Title = md.PostTitle LIMIT 1)
ORDER BY 
    ud.UserId;