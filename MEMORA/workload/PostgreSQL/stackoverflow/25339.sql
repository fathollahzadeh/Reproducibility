
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        PHT2.Name AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS RecentActivityRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = p.Id
    LEFT JOIN 
        Posts A ON A.ParentId = p.Id
    LEFT JOIN 
        PostHistory PH ON PH.PostId = p.Id AND PH.PostHistoryTypeId = 10 
    LEFT JOIN 
        PostHistoryTypes PHT2 ON PH.PostHistoryTypeId = PHT2.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, U.DisplayName, PHT2.Name, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        AnswerCount,
        CloseReason
    FROM 
        RankedPosts
    WHERE 
        RecentActivityRank = 1 
)
SELECT 
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.CreationDate,
    fp.ViewCount,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.AnswerCount,
    COALESCE(fp.CloseReason, 'Open') AS Status,
    STRING_AGG(DISTINCT U.DisplayName, ', ') AS Contributors
FROM 
    FilteredPosts fp
LEFT JOIN 
    Votes V ON V.PostId = fp.PostId AND V.VoteTypeId = 2 
LEFT JOIN 
    Users U ON V.UserId = U.Id
GROUP BY 
    fp.Title, fp.Body, fp.Tags, fp.CreationDate, fp.ViewCount, fp.OwnerDisplayName, fp.CommentCount, fp.AnswerCount, fp.CloseReason
ORDER BY 
    fp.ViewCount DESC,
    fp.CreationDate DESC
LIMIT 10;
